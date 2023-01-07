#![cfg_attr(
    all(not(debug_assertions), target_os = "windows"),
    windows_subsystem = "windows"
)]

#[tauri::command]
fn greet(name: &str) -> Result<String, String> {
    if name == "waffles" {
        Ok(format!("Hello Elm '{:}', welcome to Tauri", name))
    } else {
        Err("fbfbfbfbf".to_owned())
    }
}

#[derive(serde::Serialize)]
struct Data {
    waffles: String
}

#[derive(serde::Serialize)]
struct Waffle {
    count: i32
}

#[tauri::command]
fn data() -> Result<Data, String> {
    Ok(Data{
        waffles: "are great".into()
    })
}

#[tauri::command]
fn get_waffle() -> Result<Waffle, String> {
    Ok(Waffle{
        count: 12
    })
}

#[derive(serde::Serialize)]
struct Response {
    status: u16,
    body: String,
}

#[derive(serde::Deserialize)]
struct Request {
    url: String,
}

#[tauri::command(async)]
async fn http_request(request: Request) -> Result<Response, String> {
    let resp = reqwest::get(request.url).await;
    match resp {
        Ok(r) => {
            let status_code = r.status().as_u16();
            match r.text().await {
                Ok(b) => {
                    Ok(Response{
                        body: b,
                        status: status_code,
                    })
                }
                Err(e) => Err("could not get text".into()),
            }
        },
        Err(e) => Err("we are out of waffles".into()),
    }
}

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![greet, data, get_waffle, http_request])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
