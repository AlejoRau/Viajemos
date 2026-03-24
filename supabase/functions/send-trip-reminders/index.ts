import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// Scheduled via pg_cron — runs daily at 08:00 ART (11:00 UTC).
// Finds trips departing within the next 24 hours and inserts
// trip_reminder notifications for owners and accepted passengers.
// Uses service role key because it reads across all users' data.

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

Deno.serve(async (req: Request) => {
  // Validate cron secret
  const secret = Deno.env.get("CRON_SECRET");
  if (secret) {
    const auth = req.headers.get("x-cron-secret");
    if (auth !== secret) {
      return new Response("Unauthorized", { status: 401 });
    }
  }

  const now = new Date();
  const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
  const todayDate = now.toISOString().split("T")[0];
  const tomorrowDate = tomorrow.toISOString().split("T")[0];

  // Find trips departing today or tomorrow that are not cancelled/completed
  const { data: trips, error: tripError } = await supabase
    .from("trips")
    .select("id, owner_id, destination_address, departure_date, departure_time")
    .in("status", ["open", "full", "in_progress"])
    .gte("departure_date", todayDate)
    .lte("departure_date", tomorrowDate);

  if (tripError) {
    console.error("Error fetching trips:", tripError);
    return new Response("DB error", { status: 500 });
  }

  if (!trips || trips.length === 0) {
    return new Response(
      JSON.stringify({ notified: 0, reason: "no_upcoming_trips" }),
      { headers: { "Content-Type": "application/json" } }
    );
  }

  let notified = 0;

  for (const trip of trips) {
    const dateLabel = trip.departure_date === todayDate ? "hoy" : "mañana";
    const timeLabel = trip.departure_time
      ? ` a las ${trip.departure_time.slice(0, 5)}`
      : "";
    const body = `Tu viaje a ${trip.destination_address} sale ${dateLabel}${timeLabel}.`;

    // Notify the owner
    await supabase.from("notifications").insert({
      user_id: trip.owner_id,
      type: "trip_reminder",
      title: "Recordatorio de viaje",
      body,
      data: { trip_id: trip.id },
    });
    notified++;

    // Notify accepted passengers
    const { data: requests } = await supabase
      .from("trip_requests")
      .select("passenger_id")
      .eq("trip_id", trip.id)
      .eq("status", "accepted");

    for (const request of requests ?? []) {
      await supabase.from("notifications").insert({
        user_id: request.passenger_id,
        type: "trip_reminder",
        title: "Recordatorio de viaje",
        body,
        data: { trip_id: trip.id },
      });
      notified++;
    }
  }

  console.log(
    `Trip reminders sent: ${notified} notifications for ${trips.length} trip(s)`
  );

  return new Response(JSON.stringify({ notified, trips: trips.length }), {
    headers: { "Content-Type": "application/json" },
  });
});
