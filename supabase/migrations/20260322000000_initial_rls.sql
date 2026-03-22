-- 1. Ativar RLS em todas as tabelas
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_admin ENABLE ROW LEVEL SECURITY;

-- 2. Políticas para 'profiles'
CREATE POLICY "Profiles são visíveis por todos" ON public.profiles
    FOR SELECT USING (true);

CREATE POLICY "Utilizadores podem editar o seu próprio perfil" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- 3. Políticas para 'games'
CREATE POLICY "Jogos são visíveis por todos" ON public.games
    FOR SELECT USING (true);

CREATE POLICY "Utilizadores autenticados podem criar jogos" ON public.games
    FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Apenas o organizador pode editar o seu jogo" ON public.games
    FOR UPDATE USING (auth.uid() = created_by);

CREATE POLICY "Apenas o organizador pode apagar o seu jogo" ON public.games
    FOR DELETE USING (auth.uid() = created_by);

-- 4. Políticas para 'attendances'
CREATE POLICY "Presenças são visíveis por todos" ON public.attendances
    FOR SELECT USING (true);

CREATE POLICY "Utilizadores podem gerir a sua própria presença" ON public.attendances
    FOR ALL USING (auth.uid() = user_id);

-- 5. Políticas para 'game_admin' (Dados sensíveis)
-- Apenas o organizador do jogo (definido na tabela games) pode aceder a estes dados
CREATE POLICY "Apenas o organizador pode ver dados admin do jogo" ON public.game_admin
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.games 
            WHERE games.id = game_admin.game_id 
            AND games.created_by = auth.uid()
        )
    );

CREATE POLICY "Apenas o organizador pode editar dados admin do jogo" ON public.game_admin
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.games 
            WHERE games.id = game_admin.game_id 
            AND games.created_by = auth.uid()
        )
    );
