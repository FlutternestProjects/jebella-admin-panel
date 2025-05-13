import { createClient } from '@supabase/supabase-js';
import type { LayoutLoad } from './$types';

export const load: LayoutLoad = async () => {
    const supabase = createClient(
        import.meta.env.VITE_SUPABASE_URL,
        import.meta.env.VITE_SUPABASE_ANON_KEY
    );

    return {
        supabase
    };
}; 