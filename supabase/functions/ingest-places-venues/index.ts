import { createClient } from "jsr:@supabase/supabase-js@2";

// Ops-only: invoked manually per city. Secret-gated; NEVER exposed to the app.
Deno.serve(async (req) => {
  const secret = Deno.env.get("PLACES_INGEST_SECRET");
  if (!secret) return new Response(JSON.stringify({ error: "ingest_not_configured" }), { status: 503, headers: { "Content-Type": "application/json" } });
  if (req.headers.get("x-ingest-secret") !== secret) return new Response("forbidden", { status: 403 });
  const { city, lat, lng, radius_m = 5000, style_tag = "k_style", text_query } =
    await req.json();
  let res: Response;
  if (text_query) {
    // searchText: bat "music box"/"phong hat mini" ma searchNearby type=karaoke bo sot.
    res = await fetch("https://places.googleapis.com/v1/places:searchText", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": Deno.env.get("GOOGLE_PLACES_API_KEY")!,
        "X-Goog-FieldMask": "places.id,places.displayName,places.formattedAddress,places.location",
      },
      body: JSON.stringify({
        textQuery: text_query,
        pageSize: 20, // pageSize max 20; chua phan trang (pageToken) -> quan day dac co the bi cat
        languageCode: "vi",
        regionCode: "VN",
        locationBias: { circle: { center: { latitude: lat, longitude: lng }, radius: radius_m } },
      }),
    });
  } else {
    res = await fetch("https://places.googleapis.com/v1/places:searchNearby", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": Deno.env.get("GOOGLE_PLACES_API_KEY")!,
        "X-Goog-FieldMask": "places.id,places.displayName,places.formattedAddress,places.location",
      },
      body: JSON.stringify({
        includedTypes: ["karaoke"],
        maxResultCount: 20,
        locationRestriction: { circle: { center: { latitude: lat, longitude: lng }, radius: radius_m } },
      }),
    });
  }
  if (!res.ok) {
    return new Response(JSON.stringify({ error: `places_api_${res.status}`, detail: await res.text() }), {
      status: 502, headers: { "Content-Type": "application/json" },
    });
  }
  const data = await res.json();
  const places: any[] = data.places ?? [];
  // locationBias co the tra ket qua NGOAI vung tron -> loc cung theo khoang cach
  // (searchNearby da hard-filter bang locationRestriction, khong can loc lai).
  const withinRadius = (p: any) => {
    const dLat = (p.location.latitude - lat) * Math.PI / 180;
    const dLng = (p.location.longitude - lng) * Math.PI / 180;
    const a = Math.sin(dLat / 2) ** 2 +
      Math.cos(lat * Math.PI / 180) * Math.cos(p.location.latitude * Math.PI / 180) *
      Math.sin(dLng / 2) ** 2;
    return 6371000 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)) <= radius_m;
  };
  const filtered = text_query ? places.filter((p) => p.id && p.location && withinRadius(p)) : places;
  const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  let upserted = 0;
  for (const p of filtered) {
    if (!p.id) continue;
    const row = {
      name: p.displayName?.text ?? "Karaoke",
      address: p.formattedAddress ?? "",
      city,
      location: `SRID=4326;POINT(${p.location.longitude} ${p.location.latitude})`, // EWKT → geography
      style_tag,
      source: "places",
      places_id: p.id,
      is_active: true,
    };
    const { error } = await sb.from("venues").upsert(row, { onConflict: "places_id" });
    if (!error) upserted++;
  }
  return new Response(JSON.stringify({ found: places.length, kept: filtered.length, upserted }), {
    headers: { "Content-Type": "application/json" },
  });
});
