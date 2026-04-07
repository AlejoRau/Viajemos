class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xowrngxyiuoaamhwxzng.supabase.co',
  );
  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhvd3JuZ3h5aXVvYWFtaHd4em5nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQzMTc0MDMsImV4cCI6MjA4OTg5MzQwM30.schQk8tqz17LBEgsrhzeGpf7MYFxm24svR-cw_FyZIg',
  );
}
