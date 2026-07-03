{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine({
      // Critical: Ensures Mizan's market images load without CORS errors
      renderer: "html",
    });
    await appRunner.runApp();
  }
});