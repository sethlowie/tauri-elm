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
    waffles: String,
}

#[derive(serde::Serialize)]
struct Waffle {
    count: i32,
}

#[tauri::command]
fn data() -> Result<Data, String> {
    Ok(Data {
        waffles: "are great".into(),
    })
}

#[tauri::command]
fn get_waffle() -> Result<Waffle, String> {
    Ok(Waffle { count: 12 })
}

fn main() {
    tauri::Builder::default()
        .plugin(tauri_elm::init())
        .invoke_handler(tauri::generate_handler![greet, data, get_waffle,])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
