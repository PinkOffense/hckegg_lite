# 🚀 Quick Start - Setup Supabase Database

## ⚡ Passos Rápidos (5 minutos)

### Passo 1: Limpar database
1. Vá para: https://supabase.com/dashboard
2. Selecione o projeto **HCKEgg Lite**
3. Menu lateral → **SQL Editor**
4. Clique em **New Query**
5. Copie **TODO** o ficheiro `cleanup.sql` deste diretório
6. Cole no editor
7. Clique em **RUN** ▶️
8. Aguarde mensagem: "Cleanup completo!"

---

### Passo 2: Criar tabelas novas
1. No mesmo **SQL Editor**, clique em **New Query** (ou limpe a anterior)
2. Copie **TODO** o ficheiro `schema.sql` deste diretório
3. Cole no editor
4. Clique em **RUN** ▶️
5. Aguarde ~10 segundos

---

### Passo 3: Verificar
1. Menu lateral → **Table Editor**
2. Deve ver **3 tabelas**:
   - ✅ `daily_egg_records`
   - ✅ `expenses`
   - ✅ `vet_records`

---

## ✅ Pronto!

Se vê as 3 tabelas, está tudo configurado! 🎉

Agora pode:
1. Fazer merge do PR
2. Testar a aplicação
3. Dados serão guardados no Supabase

---

## ❌ Se der erro

### Erro: "permission denied"
→ Verifique se está logado no projeto correto

### Erro: "relation already exists"
→ Execute o `cleanup.sql` primeiro

### Erro: "syntax error"
→ Certifique-se que copiou TODO o ficheiro (do início ao fim)

### Outras dúvidas
→ Veja `README.md` para instruções detalhadas
