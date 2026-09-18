/**
 * V-Hab Reusable Supabase Client (JavaScript/Web)
 * Uses environment variables:
 * - VITE_SUPABASE_URL
 * - VITE_SUPABASE_PUBLISHABLE_KEY
 */

import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const supabaseUrl =
  (typeof process !== 'undefined' && process.env?.VITE_SUPABASE_URL) ||
  (typeof window !== 'undefined' && window.__ENV__?.VITE_SUPABASE_URL) ||
  (typeof window !== 'undefined' && window.VITE_SUPABASE_URL) ||
  '';

const supabaseAnonKey =
  (typeof process !== 'undefined' && process.env?.VITE_SUPABASE_PUBLISHABLE_KEY) ||
  (typeof window !== 'undefined' && window.__ENV__?.VITE_SUPABASE_PUBLISHABLE_KEY) ||
  (typeof window !== 'undefined' && window.VITE_SUPABASE_PUBLISHABLE_KEY) ||
  '';

export const supabase = supabaseUrl && supabaseAnonKey
  ? createClient(supabaseUrl, supabaseAnonKey)
  : null;

export default supabase;
