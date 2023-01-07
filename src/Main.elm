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


testHttp : Cmd Msg
testHttp =
    Tauri.request
        { url = "https://swapi.dev/api/people/3/"
        , expect = Tauri.expectString GotTestHttp
        }
    -- Tauri.invoke
    --     { command = "http_request"
    --     , body =
    --         Tauri.jsonBody <|
    --             E.object
    --                 [ ( "request"
    --                   , E.object
    --                         [ ( "url", E.string "https://swapi.dev/api/people/2/" ) ]
    --                   )
    --                 ]
    --     , expect = Tauri.expectString GotTestHttp
    --     }


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
    }


initialModel : Model
initialModel =
    { greet = ""
    , name = ""
    , notFound = ""
    , waffles = ""
    , testHttp = ""
    }



-- MSG


type Msg
    = GotGreet (Result Tauri.Error String)
    | Greet
    | GotNotFound (Result Tauri.Error ())
    | GotWaffle (Result Tauri.Error Waffles)
    | GotTestHttp (Result Tauri.Error String)
    | UpdateName String



-- INIT


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( initialModel
    , Cmd.batch
        [ notFound
        , getWaffle
        , testHttp
        ]
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "MSG" msg of
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
                ]
        ]
    }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
