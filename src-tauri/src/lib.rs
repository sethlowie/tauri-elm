use directories::ProjectDirs;
use std::{
    error::Error,
    fmt,
    fs::create_dir_all,
    io::{Read, Write},
    sync::Mutex,
};
use tauri::{plugin::TauriPlugin, Manager, Runtime};

pub fn init<R: Runtime>() -> TauriPlugin<R> {
    tauri::plugin::Builder::new("tauri-elm")
        .invoke_handler(tauri::generate_handler![
            http_request,
            read_file,
            write_file,
        ])
        .setup(|app_handler| {
            if let Some(proj_dir) = ProjectDirs::from("com", "tauri-elm", "test-app") {
                if let Err(err) = create_dir_all(proj_dir.data_dir()) {
                    Err(Box::new(SetupError(format!(
                        "Could not create data dir: {}",
                        err
                    ))))
                } else {
                    app_handler.manage(default_state(proj_dir));
                    Ok(())
                }
            } else {
                Err(Box::new(SetupError("Could not setup plugin".into())))
            }
        })
        .build()
}

#[derive(Debug)]
struct SetupError(String);

impl fmt::Display for SetupError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "There is an error: {}", self.0)
    }
}

impl Error for SetupError {}

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
                Ok(b) => Ok(Response {
                    body: b,
                    status: status_code,
                }),
                Err(err) => Err(format!("Could not get text from response: {}", err)),
            }
        }
        Err(err) => Err(format!("Could not make request: {}", err)),
    }
}

#[tauri::command]
fn read_file(state: tauri::State<AppState>, name: String) -> Result<String, String> {
    let app_state = state.0.lock().unwrap();
    let path = app_state.proj_dir.data_dir().join(name);

    let file = std::fs::OpenOptions::new()
        .write(true)
        .read(true)
        .create(true)
        .open(&path);

    match file {
        Ok(mut f) => {
            let mut buf = String::new();
            match f.read_to_string(&mut buf) {
                Ok(_) => Ok(buf),
                Err(err) => Err(format!("--- {}", err)),
            }
        }
        Err(err) => Err(format!("<<< {} {}", path.display().to_string(), err)),
    }
}

#[tauri::command]
fn write_file(state: tauri::State<AppState>, name: String, data: String) -> Result<(), String> {
    let app_state = state.0.lock().unwrap();
    let path = app_state.proj_dir.data_dir().join(name);

    let file = std::fs::OpenOptions::new()
        .write(true)
        .create(true)
        .open(&path);

    println!("saving the data: {}", data);

    match file {
        Ok(mut f) => match f.write_all(&data.as_bytes()) {
            Ok(()) => Ok(()),
            Err(err) => Err(err.to_string()),
        },
        Err(err) => Err(format!("{} {}", path.display().to_string(), err)),
    }
}

struct AppState(Mutex<App>);

struct App {
    // authenticate: bool,
    // keys: std::collections::HashMap<String, String>,
    proj_dir: ProjectDirs,
}

fn default_state(proj_dir: ProjectDirs) -> AppState {
    AppState(Mutex::new(App {
        // authenticate: false,
        // keys: std::collections::HashMap::new(),
        proj_dir,
    }))
}
