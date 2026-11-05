export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // Endpoint for version check: /version.json
    if (url.pathname === "/version.json") {
      return new Response(
        JSON.stringify({
          name: "MARJUK AMIN WINDOWS TOOLKIT",
          version: "1.0.0",
          tagline: "A better way to manage Windows.",
          portal: "https://wintoolkit.marjukamin.com",
          repository: "https://github.com/Marjuk06/marjuk-windows-toolkit"
        }, null, 2),
        {
          headers: {
            "Content-Type": "application/json; charset=utf-8",
            "Cache-Control": "public, max-age=300"
          }
        }
      );
    }

    // Default route: Serve the official bootstrap script for:
    // irm https://wintoolkit.marjukamin.com | iex
    const bootstrapSourceUrl = "https://raw.githubusercontent.com/Marjuk06/marjuk-windows-toolkit/main/scripts/bootstrap.ps1";

    try {
      const response = await fetch(bootstrapSourceUrl, {
        cf: {
          cacheTtl: 60,
          cacheEverything: true
        }
      });

      if (!response.ok) {
        return new Response("# Error fetching bootstrap script from GitHub", {
          status: 502,
          headers: { "Content-Type": "text/plain; charset=utf-8" }
        });
      }

      const scriptBody = await response.text();

      return new Response(scriptBody, {
        status: 200,
        headers: {
          "Content-Type": "text/plain; charset=utf-8",
          "Cache-Control": "public, max-age=60",
          "X-Content-Type-Options": "nosniff"
        }
      });
    } catch (error) {
      return new Response(`# Bootstrap Service Error: ${error.message}`, {
        status: 500,
        headers: { "Content-Type": "text/plain; charset=utf-8" }
      });
    }
  }
};
