module Main exposing (main)

import Browser exposing (Document)
import Component.Container
import Element exposing (..)
import Element.Font as Font
import Element.Input as Input
import Json.Decode as D
import Json.Decode.Pipeline exposing (required)
import Json.Encode as E
import Tauri


testRead : Cmd Msg
testRead =
    Tauri.readFile
        { name = "waffles.txt"
        , expect = Tauri.expectString GotReadTest
        }


saveEmail : String -> Cmd Msg
saveEmail email =
    Tauri.writeFile
        { name = "email.txt"
        , data = email
        , expect = Tauri.expectWhatever EmailSaved
        }


getEmail : Cmd Msg
getEmail =
    Tauri.readFile
        { name = "email.txt"
        , expect = Tauri.expectString GotEmail
        }


testHttp : Cmd Msg
testHttp =
    Tauri.request
        { url = "https://swapi.dev/api/people/3/"
        , expect = Tauri.expectString GotTestHttp
        }


greet : String -> Cmd Msg
greet name =
    Tauri.invoke
        { command = "greet"
        , expect = Tauri.expectString GotGreet
        , body =
            Tauri.jsonBody <|
                E.object
                    [ ( "name", E.string name ) ]
        }


notFound : Cmd Msg
notFound =
    Tauri.invoke
        { command = "not-found"
        , expect = Tauri.expectWhatever GotNotFound
        , body = Tauri.emptyBody
        }


type alias Waffles =
    { count : Int
    }


decodeWaffle : D.Decoder Waffles
decodeWaffle =
    D.succeed Waffles
        |> required "count" D.int


getWaffle : Cmd Msg
getWaffle =
    Tauri.invoke
        { command = "get_waffle"
        , body = Tauri.emptyBody
        , expect = Tauri.expectJson GotWaffle decodeWaffle
        }


main : Program Flags Model Msg
main =
    Browser.document
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- FLAGS


type alias Flags =
    {}



-- MODEL


type alias Model =
    { greet : String
    , name : String
    , notFound : String
    , waffles : String
    , testHttp : String
    , testRead : String
    , email : String
    }


initialModel : Model
initialModel =
    { greet = ""
    , name = ""
    , notFound = ""
    , waffles = ""
    , testHttp = "never fetched"
    , testRead = "waiting"
    , email = ""
    }



-- MSG


type Msg
    = GotGreet (Result Tauri.Error String)
    | Greet
    | GotNotFound (Result Tauri.Error ())
    | GotWaffle (Result Tauri.Error Waffles)
    | GotTestHttp (Result Tauri.Error String)
    | GotReadTest (Result Tauri.Error String)
    | EmailSaved (Result Tauri.Error ())
    | GotEmail (Result Tauri.Error String)
    | GetEmail
    | SaveEmail
    | UpdateName String
    | UpdateEmail String



-- INIT


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( initialModel
    , Cmd.batch
        [ notFound
        , getWaffle
        , getEmail
        , testHttp
        , testRead
        ]
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "MSG" msg of
        UpdateEmail email ->
            ( { model | email = email }, Cmd.none )

        GotReadTest (Ok str) ->
            ( { model | testRead = str }, Cmd.none )

        GotReadTest (Err err) ->
            ( { model | testRead = Tauri.errorToString err }, Cmd.none )

        Greet ->
            ( model, greet model.name )

        GotGreet (Ok m) ->
            ( { model | greet = m }, Cmd.none )

        GotGreet (Err err) ->
            ( { model | greet = Tauri.errorToString err }, Cmd.none )

        GotTestHttp (Ok str) ->
            ( { model | testHttp = str }, Cmd.none )

        GotTestHttp (Err err) ->
            ( { model | testHttp = Tauri.errorToString err }, Cmd.none )

        GotWaffle (Ok waffle) ->
            ( { model | waffles = String.fromInt waffle.count ++ " total waffles" }, Cmd.none )

        GotWaffle (Err err) ->
            ( { model | waffles = Tauri.errorToString err }, Cmd.none )

        UpdateName name ->
            ( { model | name = name }, Cmd.none )

        GotNotFound (Ok _) ->
            ( model, Cmd.none )

        GotNotFound (Err err) ->
            ( { model | notFound = Tauri.errorToString err }, Cmd.none )

        EmailSaved (Ok ()) ->
            ( model, Cmd.none )

        EmailSaved (Err err) ->
            ( { model | email = Tauri.errorToString err }, Cmd.none )

        GotEmail (Ok email) ->
            ( { model | email = email }, Cmd.none )

        GotEmail (Err err) ->
            ( { model | email = Tauri.errorToString err }, Cmd.none )

        GetEmail ->
            ( { model | email = "waiting" }, getEmail )

        SaveEmail ->
            ( { model | email = "waiting" }, saveEmail model.email )




-- VIEW


view : Model -> Document Msg
view model =
    { title = "My App"
    , body =
        [ Component.Container.app [] <|
            column [ spacing 36 ]
                [ Input.text []
                    { label =
                        Input.labelAbove [] <|
                            text "Name"
                    , onChange = UpdateName
                    , placeholder = Nothing
                    , text = model.name
                    }
                , Input.button [ Font.bold ]
                    { label = text "Greet"
                    , onPress = Just Greet
                    }
                , paragraph []
                    [ el [] <| text "GREETING: "
                    , el [] <| text model.greet
                    ]
                , paragraph []
                    [ el [] <| text "NOT FOUND: "
                    , el [] <| text model.notFound
                    ]
                , paragraph []
                    [ el [] <| text "WAFFLE: "
                    , el [] <| text model.waffles
                    ]
                , paragraph []
                    [ el [] <| text "HTTP TEST: "
                    , el [] <| text model.testHttp
                    ]
                , paragraph []
                    [ el [] <| text "READ TEST:"
                    , el [] <| text model.testRead
                    ]
                , Input.text
                    [ Font.color (rgba255 12 12 12 1)
                    ]
                    { label =
                        Input.labelAbove [] <|
                            text "Email"
                    , onChange = UpdateEmail
                    , placeholder = Nothing
                    , text = model.email
                    }
                , Input.button []
                    { onPress = Just SaveEmail
                    , label = text "Save Email"
                    }
                ]
        ]
    }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
