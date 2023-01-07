dev:
	cargo tauri dev

build:
	cargo tauri build

dev-ui:
	elm-live ./src/Main.elm -u -p 5050 -- --output=dist/main.js;

build-ui:
	elm make src/Main.elm --optimize --output=main.js;

check:
	elm make src/Main.elm --output=/dev/null
