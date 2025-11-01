-- Script de inicialização do banco de dados

-- Criar extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Configurar timezone
SET timezone = 'America/Sao_Paulo';

-- Criar índices personalizados (serão complementados pelas migrations)
-- Este arquivo é executado antes das migrations do Django
