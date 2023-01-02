dev:
	elm-live ./src/Main.elm -u -p 5050 -- --output=dist/main.js;

build:
	elm make src/Main.elm --optimize --output=main.js;
