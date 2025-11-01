# 💈 Sistema de Gerenciamento de Barbearia

> Sistema completo de agendamentos para barbearias desenvolvido com **Flutter** e **Django REST Framework**

[![Flutter](https://img.shields.io/badge/Flutter-3.9.2-02569B?logo=flutter)](https://flutter.dev)
[![Django](https://img.shields.io/badge/Django-4.2-092E20?logo=django)](https://www.djangoproject.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14-4169E1?logo=postgresql)](https://www.postgresql.org/)
[![Docker](https://img.shields.io/badge/Docker-Enabled-2496ED?logo=docker)](https://www.docker.com/)

---

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Funcionalidades](#-funcionalidades)
- [Tecnologias](#️-tecnologias)
- [Arquitetura](#-arquitetura)
- [Instalação](#-instalação)
- [Configuração](#️-configuração)
- [Uso](#-uso)
- [API](#-api)
- [Testes](#-testes)
- [Deploy](#-deploy)
- [Contribuindo](#-contribuindo)

---

## 🎯 Visão Geral

Aplicativo mobile multiplataforma (Android/iOS) para gestão completa de barbearias, oferecendo:

- **Sistema de agendamento inteligente** com horários dinâmicos
- **3 perfis de usuário** distintos (Admin, Barbeiro, Cliente)
- **Gestão completa** de serviços, barbeiros e agendamentos
- **Interface moderna** com tema dark premium
- **Notificações em tempo real**
- **Relatórios e analytics**

### 👥 Perfis de Usuário

#### 👨‍💼 Administrador
Controle total do sistema com dashboard executivo, gerenciamento de usuários, serviços, relatórios avançados e configurações críticas.

#### ✂️ Barbeiro
Gerenciamento de agenda pessoal, confirmação de atendimentos, controle de disponibilidade e visualização de estatísticas.

#### 👤 Cliente
Agendamento de serviços, visualização de histórico, gerenciamento de perfil e avaliação de atendimentos.

---

## 🚀 Funcionalidades

### 🔐 Autenticação e Perfis

- **Login/Registro** seguro com validação em tempo real
- **Recuperação de senha** via email
- **Edição de perfil** com upload de foto
- **Campos permanentes** (usuário e email) protegidos
- **Verificação única** de email e username

### 👨‍💼 Painel do Administrador

#### 📊 Dashboard
- **Estatísticas em tempo real**:
  - Contador de barbeiros ativos
  - Total de serviços disponíveis
  - Agendamentos (com filtros de período)
- **Filtros de período**: Hoje, Esta Semana, Este Mês, Todos
- **Atividades recentes** (últimas 10 ações)
- **Pull-to-refresh** para atualização instantânea

#### 👥 Gerenciamento de Usuários
**Aba unificada com navegação interna**

**Barbeiros**:
- ✅ Criação com validação em tempo real
- ✅ Verificação de email/username únicos
- ✅ Telefone no formato brasileiro (+55)
- ✅ Toggle ativo/inativo
- ✅ Edição e exclusão

**Clientes**:
- 🔍 **Busca avançada** (nome, email, username)
- 📊 Contador de resultados
- 👁️ Visualização de detalhes em modal
- 🗑️ Exclusão com confirmação
- 🔄 Pull-to-refresh

#### 📋 Gerenciamento de Serviços
- **CRUD completo**: Criar, editar, ativar/desativar
- **Campos**: Nome, descrição, duração (minutos), preço
- **Cards visuais** com informações completas
- **Validação de preços** e durações

#### 📅 Gerenciamento de Agendamentos
**Filtros avançados**:
- 📌 **Status**: Todos, Pendentes, Confirmados, Concluídos, Cancelados
- 📅 **Data**: Hoje, Esta Semana, Este Mês, Personalizado (range)
- ✂️ **Barbeiro**: Dropdown com todos os barbeiros
- 👤 **Cliente**: Dropdown com todos os clientes

**Visualização**:
- Cards organizados por data/hora
- Badges de status coloridos
- Contador de resultados filtrados
- Botão "Limpar Filtros"
- Detalhes completos em modal

#### 📈 Relatórios e Analytics
- 📊 Gráficos de status de agendamentos
- 🏆 Top 5 serviços mais vendidos
- 🥇 Top 5 barbeiros (com medalhas)
- 📉 Tendências mensais
- 💰 Receita total
- 📄 Exportação de relatórios

#### ⚙️ Configurações Avançadas

**Informações Pessoais**:
- Edição de perfil (nome, telefone)
- Alteração de senha segura
- Visualização de estatísticas

**Ações Rápidas**:
- 💾 **Backup de Dados**: Exportar JSON
- 🔄 **Limpar Cache**: Liberar espaço

**Zona de Perigo** ⚠️:
- 🗑️ **Reset de Banco**: Apaga TODOS os dados
  - Requer senha do admin
  - Confirmação dupla
  - ⚠️ AÇÃO IRREVERSÍVEL

### ✂️ Painel do Barbeiro

#### 🏠 Home
- **Estatísticas do dia**: Concluídos, Pendentes, Agendados
- **Próximos 3 atendimentos** com informações completas
- **Ações rápidas**: Confirmar/Cancelar via swipe gestures

#### 📅 Agenda
- **Visualização por data** (navegação fácil)
- **Filtros de status**: Pendentes (padrão), Todos, Confirmados, Concluídos, Cancelados
- **Swipe gestures**:
  - ← Cancelar (vermelho)
  - → Concluir (verde)
- **Menu de 3 pontos** para ações adicionais
- **Auto-conclusão** de atendimentos após horário

#### 👤 Perfil
- **Edição completa**: Nome, telefone, foto
- **Estatísticas reais**:
  - 📊 Total de Atendimentos
  - 📅 Atendimentos Hoje
  - 📆 Atendimentos Mês
- **Gerenciar Disponibilidade**: Configurar horários por dia da semana
- **Gerenciar Serviços**: Selecionar serviços que oferece
- **Avatar dinâmico** com foto de perfil

### 👤 Painel do Cliente

#### 🏠 Dashboard
- **Próximo agendamento** em destaque com countdown
  - ⏱️ Tempo restante formatado
  - ℹ️ Informações completas (barbeiro, serviço, horário)
  - 🔄 **Reagendar**: 3 opções (Reagendar, Cancelar, Voltar)
  - ⚠️ Restrições de tempo (30min para cancelar)
- **Navegação rápida** para agendar novo serviço

#### 📚 Histórico
**Abas separadas**:
- 📌 **Ativos**: Agendamentos futuros
- 📜 **Histórico**: Agendamentos passados
  - 📅 Filtro de data (range picker)
  - 🏷️ Badge visual do filtro ativo
  - 🔍 Resultados filtrados

#### 👤 Perfil
- **Edição de dados**: Nome, telefone, foto
- **Dados permanentes** bloqueados: Usuário, email
- **Upload de foto**: Câmera, galeria ou URL
- **Validação** de campos com feedback instantâneo

#### 📅 Novo Agendamento
**Fluxo em 3 etapas**:
1. **Escolher Barbeiro** (com foto de perfil)
2. **Selecionar Serviço** (mostra duração e preço)
3. **Escolher Data e Horário** (apenas horários disponíveis)
   - ⏰ Restrição: Mínimo 20 minutos de antecedência
   - 📅 Navegação fácil entre datas
   - ✅ Confirmação com resumo completo

---

## 🛠️ Tecnologias

### 📱 Frontend (Flutter)

```yaml
dependencies:
  flutter: sdk: flutter
  
  # Gerenciamento de Estado
  flutter_bloc: ^8.1.6
  
  # Networking
  dio: ^5.4.0
  
  # Armazenamento
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.2
  
  # UI/UX
  image_picker: ^1.0.7
  mask_text_input_formatter: ^2.7.0
  
  # Internacionalização
  intl: ^0.19.0
```

**Arquitetura**: Clean Architecture com BLoC pattern

### 🐍 Backend (Django)

```python
# Framework
Django==4.2.7
djangorestframework==3.14.0

# Database
psycopg2-binary==2.9.9

# Autenticação
djangorestframework-simplejwt==5.3.1

# Timezone
pytz==2023.3

# CORS
django-cors-headers==4.3.1

# Server
gunicorn==21.2.0
```

**Arquitetura**: Django REST Framework com PostgreSQL

### 🐳 DevOps

- **Docker & Docker Compose**: Containerização
- **Nginx**: Proxy reverso e servidor estático
- **PostgreSQL 14**: Banco de dados
- **Gunicorn**: WSGI HTTP Server

---

## 🏗️ Arquitetura

### Frontend (Flutter)

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart       # Paleta de cores
│   │   ├── app_text_styles.dart  # Tipografia
│   │   └── api_constants.dart    # URLs da API
│   ├── network/
│   │   ├── dio_client.dart       # Cliente HTTP configurado
│   │   └── api_exception.dart    # Tratamento de erros
│   └── utils/
│       ├── validators.dart       # Validadores de formulário
│       ├── snackbar_utils.dart   # Mensagens ao usuário
│       └── date_utils.dart       # Formatação de datas
├── features/
│   ├── admin/                    # Módulo Administrador
│   │   ├── admin_dashboard.dart
│   │   ├── manage_users_page.dart
│   │   ├── manage_services_page.dart
│   │   ├── manage_appointments_page.dart
│   │   ├── reports_page.dart
│   │   └── settings_page.dart
│   ├── auth/                     # Autenticação
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── repositories/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── bloc/
│   │       └── pages/
│   ├── barber/                   # Módulo Barbeiro
│   │   ├── barber_dashboard.dart
│   │   ├── manage_availability_page.dart
│   │   ├── manage_barber_services_page.dart
│   │   └── edit_barber_profile_page.dart
│   └── client/                   # Módulo Cliente
│       ├── client_dashboard.dart
│       ├── appointments_history_page.dart
│       ├── edit_profile_page.dart
│       ├── select_barber_first_page.dart
│       ├── select_service_for_barber_page.dart
│       └── booking_page.dart
└── shared/
    ├── widgets/                  # Componentes reutilizáveis
    └── utils/                    # Utilitários compartilhados
```

### Backend (Django)

```
backend/
├── apps/
│   ├── users/                    # Gerenciamento de usuários
│   │   ├── models.py
│   │   ├── serializers.py
│   │   ├── views.py
│   │   └── urls.py
│   ├── appointments/             # Agendamentos
│   │   ├── models.py
│   │   ├── serializers.py
│   │   ├── views.py
│   │   └── urls.py
│   ├── services/                 # Serviços
│   │   ├── models.py
│   │   ├── serializers.py
│   │   ├── views.py
│   │   └── urls.py
│   └── availability/             # Disponibilidade dos barbeiros
│       ├── models.py
│       ├── serializers.py
│       ├── views.py
│       └── urls.py
├── config/
│   ├── settings.py               # Configurações Django
│   ├── urls.py                   # URLs principais
│   └── wsgi.py
├── Dockerfile
├── requirements.txt
└── manage.py
```

---

## 💻 Instalação

### Pré-requisitos

- **Flutter SDK** 3.9.2 ou superior
- **Dart** 3.0.0 ou superior
- **Android Studio** / **Xcode** (para emuladores)
- **Docker** e **Docker Compose**
- **Git**

### 1. Clonar o Repositório

```bash
git clone https://github.com/seu-usuario/barbearia.git
cd barbearia
```

### 2. Configurar Backend

```bash
# Navegar para pasta do backend
cd backend

# Copiar arquivo de ambiente
cp .env.example .env

# Editar variáveis de ambiente
nano .env
```

**.env**:
```env
DEBUG=True
SECRET_KEY=sua-chave-secreta-aqui
DATABASE_NAME=barbearia_db
DATABASE_USER=postgres
DATABASE_PASSWORD=postgres
DATABASE_HOST=db
DATABASE_PORT=5432
ALLOWED_HOSTS=localhost,127.0.0.1
```

```bash
# Subir containers
docker-compose up -d

# Aplicar migrações
docker-compose exec backend python manage.py migrate

# Criar superusuário
docker-compose exec backend python manage.py createsuperuser

# Carregar dados iniciais (opcional)
docker-compose exec backend python manage.py loaddata initial_data.json
```

**Backend disponível em**: `http://localhost:7891`

### 3. Configurar Frontend

```bash
# Voltar para raiz do projeto
cd ..

# Instalar dependências
flutter pub get

# Verificar instalação
flutter doctor
```

### 4. Configurar Emulador

#### Android

```bash
# Listar emuladores disponíveis
flutter emulators

# Iniciar emulador
flutter emulators --launch <emulator-id>

# OU usar script
chmod +x setup_emulator.sh
./setup_emulator.sh
```

#### iOS (macOS apenas)

```bash
# Abrir simulador
open -a Simulator

# Listar dispositivos
xcrun simctl list devices
```

### 5. Executar Aplicativo

```bash
# Ver dispositivos conectados
flutter devices

# Executar no dispositivo
flutter run

# OU especificar dispositivo
flutter run -d emulator-5554
```

---

## ⚙️ Configuração

### Configurar URL da API

**lib/core/constants/api_constants.dart**:

```dart
class ApiConstants {
  // Desenvolvimento local
  static const String baseUrl = 'http://10.0.2.2:7891';
  
  // Produção
  // static const String baseUrl = 'https://api.suabarbearia.com';
  
  // Endpoints
  static const String login = '/auth/login/';
  static const String register = '/auth/register/';
  static const String me = '/users/me/';
  // ...
}
```

**Nota**: `10.0.2.2` é o IP especial do Android emulator para acessar `localhost` do host.

### Cores e Tema

**lib/core/constants/app_colors.dart**:

```dart
class AppColors {
  // Cores Principais
  static const Color primaryDark = Color(0xFF1C1C1C);
  static const Color surface = Color(0xFF2E2E2E);
  static const Color gold = Color(0xFFD4AF37);
  
  // Textos
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFFCCCCCC);
  
  // Status
  static const Color success = Color(0xFF00AA00);
  static const Color error = Color(0xFFFF4444);
  static const Color warning = Color(0xFFFFA500);
  static const Color info = Color(0xFF4A90E2);
}
```

---

## 📖 Uso

### Fluxo de Agendamento (Cliente)

1. **Login** como cliente
2. **Dashboard** → Ver próximo agendamento ou "Agendar Novo Serviço"
3. **Escolher Barbeiro** → Selecionar entre barbeiros disponíveis
4. **Selecionar Serviço** → Escolher serviço desejado (mostra duração e preço)
5. **Escolher Data e Horário** → Ver horários disponíveis
6. **Confirmar** → Revisar e confirmar agendamento
7. **Sucesso** → Agendamento criado (status: Pendente)

### Gerenciamento de Agenda (Barbeiro)

1. **Login** como barbeiro
2. **Agenda** → Ver agendamentos do dia
3. **Filtrar** → Selecionar status (Pendentes por padrão)
4. **Ações**:
   - **Swipe ←** para Cancelar
   - **Swipe →** para Concluir
   - **Menu ⋮** para mais opções
5. **Disponibilidade** → Configurar horários de trabalho
6. **Serviços** → Selecionar serviços que oferece

### Administração (Admin)

1. **Login** como admin
2. **Dashboard** → Visão geral com estatísticas
3. **Usuários**:
   - **Barbeiros** → Criar, editar, ativar/desativar
   - **Clientes** → Buscar, ver detalhes, excluir
4. **Serviços** → Gerenciar catálogo de serviços
5. **Agendamentos** → Filtrar e visualizar todos os agendamentos
6. **Relatórios** → Analytics e métricas
7. **Configurações**:
   - Editar perfil
   - Alterar senha
   - Backup de dados
   - **Reset de banco** (CUIDADO!)

---

## 🔌 API

### Autenticação

#### Login
```http
POST /auth/login/
Content-Type: application/json

{
  "username": "barbeiro1",
  "password": "senha123"
}
```

**Resposta**:
```json
{
  "token": "abc123...",
  "user": {
    "id": 1,
    "username": "barbeiro1",
    "email": "barbeiro@email.com",
    "is_barber": true,
    "is_staff": false
  }
}
```

#### Registro
```http
POST /auth/register/
Content-Type: application/json

{
  "username": "cliente1",
  "email": "cliente@email.com",
  "password": "senha123",
  "first_name": "João",
  "last_name": "Silva",
  "phone": "+5511999999999"
}
```

### Usuários

#### Listar Usuários (Admin)
```http
GET /users/
Authorization: Token abc123...
```

#### Meu Perfil
```http
GET /users/me/
Authorization: Token abc123...
```

#### Atualizar Perfil
```http
PATCH /users/update_profile/
Authorization: Token abc123...
Content-Type: application/json

{
  "first_name": "João",
  "last_name": "Silva",
  "phone": "+5511999999999",
  "avatar_url": "https://..."
}
```

### Serviços

#### Listar Serviços
```http
GET /services/
```

#### Criar Serviço (Admin)
```http
POST /services/
Authorization: Token abc123...
Content-Type: application/json

{
  "name": "Corte Premium",
  "description": "Corte moderno com lavagem",
  "duration_minutes": 60,
  "price": "70.00"
}
```

### Agendamentos

#### Criar Agendamento
```http
POST /appointments/
Authorization: Token abc123...
Content-Type: application/json

{
  "barber": 1,
  "service": 2,
  "scheduled_for": "2025-10-30T14:00:00-03:00",
  "notes": "Preferência de corte"
}
```

#### Listar Meus Agendamentos
```http
GET /appointments/my_appointments/
Authorization: Token abc123...
```

#### Agenda do Barbeiro
```http
GET /appointments/barber_schedule/?date=2025-10-30
Authorization: Token abc123...
```

#### Atualizar Status
```http
PATCH /appointments/{id}/update_status/
Authorization: Token abc123...
Content-Type: application/json

{
  "status": "confirmed"
}
```

**Status**: `pending`, `confirmed`, `completed`, `cancelled`

#### Horários Disponíveis
```http
GET /appointments/available_times/?barber_id=1&date=2025-10-30&service_id=2
```

#### Estatísticas do Barbeiro
```http
GET /appointments/barber_stats/
Authorization: Token abc123...
```

**Resposta**:
```json
{
  "total_completed": 42,
  "today_completed": 5,
  "month_completed": 23
}
```

### Disponibilidade

#### Horários do Barbeiro
```http
GET /barber/availability/schedules/
Authorization: Token abc123...
```

#### Meus Serviços (Barbeiro)
```http
GET /barber/my-services/
Authorization: Token abc123...
```

---

## 🧪 Testes

### Testes Unitários

```bash
# Executar todos os testes
flutter test

# Teste específico
flutter test test/features/auth/auth_test.dart

# Com coverage
flutter test --coverage

# Ver relatório de coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Testes de Integração

```bash
# Executar testes de integração
flutter test integration_test/

# Em dispositivo específico
flutter test integration_test/app_test.dart -d emulator-5554
```

### Testes do Backend

```bash
# Django tests
docker-compose exec backend python manage.py test

# Com coverage
docker-compose exec backend coverage run --source='.' manage.py test
docker-compose exec backend coverage report
```

---

## 🚀 Deploy

### Build Android (APK)

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# APK dividido por ABI (menor tamanho)
flutter build apk --split-per-abi
```

**APK gerado em**: `build/app/outputs/flutter-apk/`

### Build Android (App Bundle)

```bash
# Release Bundle (para Google Play)
flutter build appbundle --release
```

**Bundle gerado em**: `build/app/outputs/bundle/release/`

### Build iOS

```bash
# Release IPA
flutter build ios --release

# Abrir no Xcode para assinatura
open ios/Runner.xcworkspace
```

### Deploy Backend (VPS)

**1. Configurar servidor**:

```bash
# Conectar via SSH
ssh usuario@ip-do-servidor

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

**2. Deploy**:

```bash
# Clonar repositório
git clone https://github.com/seu-usuario/barbearia.git
cd barbearia/backend

# Configurar .env para produção
cp .env.example .env
nano .env  # Editar variáveis

# Subir aplicação
docker-compose -f docker-compose.prod.yml up -d

# Aplicar migrações
docker-compose exec backend python manage.py migrate

# Coletar arquivos estáticos
docker-compose exec backend python manage.py collectstatic --noinput

# Criar superusuário
docker-compose exec backend python manage.py createsuperuser
```

**3. Configurar Nginx** (Opcional):

```nginx
# /etc/nginx/sites-available/barbearia
server {
    listen 80;
    server_name api.suabarbearia.com;

    location / {
        proxy_pass http://localhost:7891;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /static/ {
        alias /var/www/barbearia/staticfiles/;
    }

    location /media/ {
        alias /var/www/barbearia/media/;
    }
}
```

```bash
# Ativar site
sudo ln -s /etc/nginx/sites-available/barbearia /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

**4. SSL com Certbot**:

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d api.suabarbearia.com
```

---

## 🎨 Design System

### Paleta de Cores

```
Cores Principais:
├─ Primary Dark: #1C1C1C (Background principal)
├─ Surface: #2E2E2E (Cards e superfícies)
├─ Muted: #4A4A4A (Bordas e divisores)
│
Cores de Destaque:
├─ Gold: #D4AF37 (Dourado premium - botões, destaques)
├─ Wood: #8B5E3C (Marrom madeira - secundário)
│
Textos:
├─ Text Primary: #FFFFFF (Texto principal)
├─ Text Muted: #CCCCCC (Texto secundário)
├─ Border: #3A3A3A (Bordas)
│
Status:
├─ Success: #00AA00 (Confirmado)
├─ Error: #FF4444 (Cancelado)
├─ Warning: #FFA500 (Pendente)
└─ Info: #4A90E2 (Informação)
```

### Componentes

- **Buttons**: Material Design com cores customizadas
- **Cards**: Elevação suave com bordas arredondadas
- **Forms**: Inputs com validação em tempo real
- **Badges**: Status coloridos
- **Dialogs**: Confirmações com animações
- **Snackbars**: Mensagens de feedback

---

## 📊 Recursos Avançados

### Validação em Tempo Real

- **Email**: Verifica duplicidade no backend
- **Username**: Verifica duplicidade no backend
- **Telefone**: Máscara automática brasileira
- **Senhas**: Força e confirmação

### Swipe Gestures

- **Cancelar**: Swipe da esquerda para direita (vermelho)
- **Confirmar/Concluir**: Swipe da direita para esquerda (verde)
- **Feedback visual**: Cores e ícones durante swipe
- **Confirmação**: Dialog antes de executar ação

### Filtros Avançados

**Agendamentos**:
- Status (dropdown)
- Data (range picker)
- Barbeiro (dropdown)
- Cliente (dropdown)
- Limpar todos os filtros

**Dashboard**:
- Período: Hoje, Semana, Mês, Tudo
- Atualização automática de estatísticas

### Restrições de Tempo

- **Agendamento**: Mínimo 20 minutos de antecedência
- **Cancelamento**: Até 30 minutos antes do horário
- **Auto-conclusão**: Após horário + duração do serviço

---

## 🔒 Segurança

### Autenticação

- **Token-based**: Tokens seguros com expiração
- **Armazenamento**: flutter_secure_storage para tokens
- **Refresh**: Renovação automática de tokens

### Autorização

- **Níveis de acesso**: Admin, Barbeiro, Cliente
- **Verificação no backend**: Cada endpoint valida permissões
- **Guards no frontend**: Navegação baseada em perfil

### Validação

- **Input sanitization**: Previne XSS
- **SQL injection**: ORM do Django protege
- **CSRF protection**: Django middleware
- **Rate limiting**: Previne abuso da API

---

## 🐛 Troubleshooting

### Problema: "Erro ao conectar com o backend"

**Solução**:
1. Verificar se backend está rodando: `docker-compose ps`
2. Verificar URL em `api_constants.dart`
3. Android emulator: usar `10.0.2.2` em vez de `localhost`
4. iOS simulator: usar `localhost` ou IP da máquina

### Problema: "Token inválido"

**Solução**:
1. Fazer logout e login novamente
2. Limpar cache: Settings → Clear Cache
3. Verificar expiração do token no backend

### Problema: "Disponibilidade não carrega"

**Solução**:
1. Verificar se usuário é barbeiro
2. Verificar endpoint `/barber/availability/schedules/`
3. Ver logs do backend: `docker-compose logs backend`

### Problema: "Foto não aparece"

**Solução**:
1. Verificar URL da imagem (deve ser HTTPS válida)
2. Verificar campo `avatar_url` no banco
3. Fazer logout/login para recarregar dados

---

## 📚 Documentação Adicional

### Arquivos de Referência

- `docker-compose.yml` - Configuração de containers
- `pubspec.yaml` - Dependências Flutter
- `requirements.txt` - Dependências Python/Django
- `analysis_options.yaml` - Regras de lint Flutter

### Scripts Úteis

```bash
# Reiniciar backend
docker-compose restart backend

# Ver logs do backend
docker-compose logs -f backend

# Acessar shell do Django
docker-compose exec backend python manage.py shell

# Backup do banco
docker-compose exec db pg_dump -U postgres barbearia_db > backup.sql

# Restaurar banco
docker-compose exec -T db psql -U postgres barbearia_db < backup.sql

# Hot reload Flutter
r  # No terminal do flutter run

# Hot restart Flutter
R  # No terminal do flutter run
```

---

## 🤝 Contribuindo

### Como Contribuir

1. **Fork** o repositório
2. **Clone** seu fork: `git clone https://github.com/seu-usuario/barbearia.git`
3. **Crie uma branch**: `git checkout -b feature/nova-funcionalidade`
4. **Faça suas alterações** e commit: `git commit -m 'Adiciona nova funcionalidade'`
5. **Push**: `git push origin feature/nova-funcionalidade`
6. **Abra um Pull Request**

### Padrões de Código

#### Flutter (Dart)

- **Lint**: Seguir `analysis_options.yaml`
- **Naming**: CamelCase para classes, snake_case para arquivos
- **Comentários**: Documentar funções complexas
- **Widgets**: Preferir StatelessWidget quando possível
- **BLoC**: Um Bloc por feature

#### Django (Python)

- **PEP 8**: Seguir guia de estilo Python
- **Docstrings**: Documentar classes e funções
- **Type hints**: Usar quando possível
- **Migrations**: Nunca commitar migrations sem testar

### Code Review

Todos os PRs passam por review com foco em:
- ✅ Funcionalidade correta
- ✅ Testes passando
- ✅ Sem regressões
- ✅ Código limpo e documentado

---

## 📝 Changelog

### v2.1.0 (30/10/2025) - Melhorias do Barbeiro

**Novas Funcionalidades**:
- ✅ **Edição de Perfil do Barbeiro**
  - Upload de foto (câmera, galeria ou URL)
  - Campos permanentes bloqueados (usuário, email)
  - Validação de telefone com máscara
- ✅ **Estatísticas Reais**
  - Total de Atendimentos
  - Atendimentos Hoje
  - Atendimentos Mês
  - Endpoint: `/appointments/barber_stats/`
- ✅ **Correções**
  - Minha Disponibilidade agora carrega corretamente
  - Gerenciar Serviços funcional
  - Parse de resposta paginada da API

**Melhorias**:
- 📊 Dashboard do barbeiro com filtros de status
- 🎨 Avatar dinâmico com foto de perfil
- 🔄 Pull-to-refresh para atualizar estatísticas
- 📱 Navegação melhorada entre telas

### v2.0.0 (30/10/2025) - Grande Atualização

**Novas Funcionalidades**:
- ✅ **Aba Usuários Unificada** (Barbeiros + Clientes)
- ✅ **Gerenciamento de Clientes** com busca avançada
- ✅ **Aba de Agendamentos** com filtros avançados
- ✅ **Filtros de Período** no Dashboard
- ✅ **Configurações Avançadas**:
  - Backup de dados
  - Limpar cache
  - Reset de banco de dados (com confirmação)
- ✅ **Edição de Perfil do Cliente**
  - Upload de foto
  - Campos permanentes bloqueados
- ✅ **Countdown para Próximo Agendamento**
- ✅ **Histórico com Abas** (Ativos/Histórico)

**Melhorias**:
- 📊 Dashboard admin com período selecionado
- 🎨 UI/UX aprimorado em todas as telas
- 👥 Gerenciamento centralizado de usuários
- 🔒 Maior segurança em ações críticas
- 📱 Bottom navigation com 5 abas

### v1.0.0 (29/10/2025) - Lançamento Inicial

- Autenticação completa (Login/Registro)
- CRUD de Barbeiros e Serviços
- Sistema de agendamentos básico
- Validação em tempo real (email/username)
- Dashboards para Admin, Barbeiro e Cliente

---

## 👥 Time

### Desenvolvedor Principal
- **Nome**: Vinícius Ventura
- **Role**: Full Stack Developer
- **Email**: contato@exemplo.com

---

## 📄 Licença

Este projeto está sob a licença **MIT**.

```
MIT License

Copyright (c) 2025 Barbearia App

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🆘 Suporte

### Reportar Bugs

Encontrou um bug? Abra uma [Issue](https://github.com/seu-usuario/barbearia/issues) com:
- Descrição detalhada do problema
- Passos para reproduzir
- Screenshots (se aplicável)
- Versão do app e dispositivo

### Solicitar Funcionalidades

Tem uma ideia? Abra uma [Feature Request](https://github.com/seu-usuario/barbearia/issues/new?template=feature_request.md)

### Contato

- **Email**: suporte@barbearia.com
- **GitHub**: [@seu-usuario](https://github.com/seu-usuario)

---

## 🎯 Roadmap Futuro

### Em Desenvolvimento
- [ ] Sistema de notificações push (Firebase)
- [ ] Chat em tempo real (barbeiro ↔ cliente)
- [ ] Sistema de avaliações e comentários
- [ ] Programa de fidelidade (pontos)

### Planejado
- [ ] Integração com pagamentos (Stripe/Mercado Pago)
- [ ] Relatórios financeiros avançados
- [ ] App para Wear OS e Apple Watch
- [ ] Modo offline com sincronização
- [ ] Dark/Light theme toggle
- [ ] Suporte a múltiplas barbearias

### Considerando
- [ ] Web Admin Panel (React)
- [ ] API pública para integrações
- [ ] Sistema de cupons e promoções
- [ ] Agendamento recorrente
- [ ] Integração com calendário (Google/Apple)

---

## 🌟 Agradecimentos

Agradecimentos especiais a:
- Comunidade Flutter
- Equipe Django
- Contribuidores do projeto
- Testadores beta

---

## 📸 Screenshots

### Admin Dashboard
![Admin Dashboard](screenshots/admin_dashboard.png)

### Agendamento Cliente
![Cliente Booking](screenshots/client_booking.png)

### Agenda Barbeiro
![Barber Schedule](screenshots/barber_schedule.png)

---

<div align="center">

**Desenvolvido com ❤️ e Flutter**

[![Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B?logo=flutter)](https://flutter.dev)
[![Django](https://img.shields.io/badge/Powered%20by-Django-092E20?logo=django)](https://www.djangoproject.com/)

[⬆ Voltar ao topo](#-sistema-de-gerenciamento-de-barbearia)

</div>

## 📱 Visão Geral

Aplicativo mobile multiplataforma (Android/iOS) para gestão de barbearias, com três perfis de usuário distintos:

- **👨‍💼 Administrador**: Gestão completa do sistema
- **✂️ Barbeiro**: Gerenciamento de agenda e atendimentos
- **👤 Cliente**: Agendamento de serviços

## 🚀 Funcionalidades Principais

### 👨‍💼 Painel do Administrador

#### 📊 Dashboard
- **Visão Geral com Filtros de Período**
  - Filtros: Hoje, Esta Semana, Este Mês, Tudo
  - Contadores em tempo real: Barbeiros, Serviços, Agendamentos
  - Atividades recentes (últimas 10 ações do sistema)
  - Atualização via pull-to-refresh

#### 👥 Gerenciamento de Usuários
Aba única com navegação interna para Barbeiros e Clientes.

**✂️ Barbeiros**:
- Listagem completa com foto de perfil
- Criação com validação em tempo real:
  - ✅ Email único (verifica duplicidade no backend)
  - ✅ Username único (verifica duplicidade no backend)
  - ✅ Telefone com formato brasileiro (+55)
- Edição de barbeiros
- Exclusão com confirmação
- Toggle de status ativo/inativo

**👤 Clientes** (NOVO):
- **Busca Avançada**:
  - Campo de busca em Nome, Email, Username
  - Contador de resultados
  - Botão para limpar busca
- **Visualização Completa**:
  - Cards com avatar (primeira letra do nome)
  - Email e telefone
  - Data de cadastro
  - Total de clientes no topo
- **Ações**:
  - 👁️ Ver Detalhes completos em modal
  - 🗑️ Excluir cliente (com confirmação)
- **Estados**:
  - Loading durante carregamento
  - Empty state quando não há clientes
  - Empty state diferenciado para busca sem resultados
  - Pull-to-refresh
- **Filtros Inteligentes**:
  - Mostra apenas usuários que NÃO são barbeiros
  - Mostra apenas usuários que NÃO são staff

#### 📋 Gerenciamento de Serviços
- CRUD completo de serviços
- Campos: Nome, Descrição, Duração, Preço
- Ativação/desativação de serviços
- Visualização em cards com informações completas

#### 📅 **NOVA: Gerenciamento de Agendamentos**
- **Filtros Avançados**:
  - Status: Todos, Pendentes, Confirmados, Concluídos, Cancelados
  - Data: Hoje, Esta Semana, Este Mês, Personalizado (range de datas)
  - Barbeiro: Dropdown com todos os barbeiros
  - Cliente: Dropdown com todos os clientes
- **Visualização Detalhada**:
  - Cards organizados com data/hora, cliente, barbeiro, serviço
  - Badge de status colorido
  - Contador de resultados filtrados
  - Botão "Limpar Filtros"
- **Detalhes do Agendamento**:
  - Modal com todas as informações
  - Histórico de criação/atualização

#### 📈 Relatórios Completos
- Gráficos de status de agendamentos
- Top 5 serviços mais vendidos
- Top 5 barbeiros (com medalhas 🥇🥈🥉)
- Tendências mensais
- Receita total
- Suporte a paginação do backend

#### ⚙️ **NOVA: Configurações Avançadas**

**Informações Pessoais**
- Edição de perfil (nome, telefone)
- Alteração de senha segura (com confirmação)
- Visualização de estatísticas pessoais

**Ações Rápidas**
- 💾 **Backup de Dados**: Exportar dados em JSON
- 🔄 **Limpar Cache**: Liberar espaço do app

**Zona de Perigo** ⚠️
- 🗑️ **Resetar Banco de Dados**:
  - Apaga TODOS os dados (barbeiros, serviços, agendamentos, clientes)
  - Requer senha do admin
  - Confirmação dupla de segurança
  - Endpoint: `/admin/reset_database/`
  - ⚠️ AÇÃO IRREVERSÍVEL!

### ✂️ Painel do Barbeiro

- Dashboard com estatísticas do dia
- Próximos 3 atendimentos
- Agenda completa com filtros
- Ações de status:
  - Pendente → [Confirmar] [Cancelar]
  - Confirmado → [Concluir] [Cancelar]
  - Completed/Cancelled → Sem ações

### 👤 Painel do Cliente

- Próximo agendamento em destaque
- Serviços favoritos (baseado em histórico)
- Histórico de agendamentos
- Ações rápidas funcionais
- Agendamento com seleção de serviço e barbeiro

## 🛠️ Tecnologias

### Frontend (Flutter)
- **Framework**: Flutter 3.x
- **Gerenciamento de Estado**: flutter_bloc
- **Navegação**: go_router
- **Requisições HTTP**: dio
- **Internacionalização**: intl (pt_BR)
- **Armazenamento Seguro**: flutter_secure_storage
- **UI/UX**: Material Design 3

### Backend (Django)
- **Framework**: Django REST Framework
- **Banco de Dados**: PostgreSQL
- **Autenticação**: Token-based (JWT)
- **Deploy**: Docker + Docker Compose
- **Proxy**: Nginx

## 📦 Estrutura do Projeto

```
lib/
├── core/
│   ├── constants/          # Cores, estilos, constantes
│   ├── network/            # Configuração Dio, interceptors
│   └── utils/              # Utilitários (validadores, formatadores)
├── features/
│   ├── admin/              # Módulo do administrador
│   │   ├── admin_dashboard.dart
│   │   ├── create_barber_page.dart
│   │   ├── manage_barbers_page.dart
│   │   ├── manage_services_page.dart
│   │   ├── manage_appointments_page.dart ⭐ NOVO
│   │   ├── reports_page.dart
│   │   └── ...
│   ├── auth/               # Autenticação
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   ├── barber/             # Módulo do barbeiro
│   └── client/             # Módulo do cliente
└── shared/                 # Componentes compartilhados
```

## 🔧 Configuração e Instalação

### Pré-requisitos
- Flutter SDK (3.x ou superior)
- Android Studio / Xcode
- Docker e Docker Compose (para backend)
- Git

### Backend

```bash
# Clonar repositório
git clone <repo-url>
cd barbearia/backend

# Subir containers Docker
docker-compose up -d

# Aplicar migrações
docker-compose exec web python manage.py migrate

# Criar superusuário
docker-compose exec web python manage.py createsuperuser
```

**Backend rodará em**: `http://localhost:7891`

### Frontend (Flutter)

```bash
# Instalar dependências
flutter pub get

# Configurar emulador Android
./setup_emulator.sh

# Executar app
flutter run
```

## 🔐 Autenticação

### Endpoints Públicos (sem autenticação)
- `/auth/login/` - Login
- `/auth/register/` - Registro
- `/users/check_email/` - Validação de email
- `/users/check_username/` - Validação de username

### Endpoints Protegidos
Requerem header `Authorization: Token <token>`

## 🎨 Design System

### Cores
- **Primária (Dourado)**: `#D4AF37`
- **Fundo Escuro**: `#1A1A1A`
- **Superfície**: `#2C2C2C`
- **Texto Principal**: `#FFFFFF`
- **Texto Secundário**: `#B0B0B0`

### Tipografia
Segue Material Design 3 com fonte Roboto

## 📱 Capturas de Tela

### Admin Dashboard
- Visão geral com estatísticas
- Filtros de período (Hoje/Semana/Mês/Tudo)
- Ações rápidas

### Gerenciamento de Agendamentos
- Lista com filtros avançados
- Cards organizados por data
- Status coloridos

### Configurações
- Editar perfil
- Alterar senha
- Ações do sistema
- **Zona de Perigo** (Reset de banco)

## 🧪 Testes

```bash
# Executar testes
flutter test

# Testes com coverage
flutter test --coverage
```

## 📚 Documentação Adicional

- `ESPECIFICACAO_PROJETO.md` - Especificação completa
- `FUNCIONALIDADES_ADMIN.md` - Detalhes do painel admin
- `SISTEMA_AGENDAMENTOS_COMPLETO.md` - Sistema de agendamentos
- `TESTES_COMPLETOS.md` - Documentação de testes
- `VALIDACAO_EMAIL_USERNAME.md` - Validação em tempo real

## 🚧 Roadmap

- [x] Autenticação multi-perfil
- [x] Dashboard admin com estatísticas
- [x] CRUD completo de barbeiros e serviços
- [x] **Gerenciamento de clientes com busca avançada**
- [x] **Sistema de agendamentos com filtros avançados**
- [x] **Configurações avançadas (backup, reset DB)**
- [x] **Filtros de período no dashboard**
- [x] Validação em tempo real (email/username)
- [x] Relatórios e analytics
- [ ] Sistema de notificações push
- [ ] Chat barbeiro-cliente
- [ ] Sistema de avaliações
- [ ] Programa de fidelidade

## 📝 Changelog

### v2.0.0 (30/10/2025) ⭐ NOVA VERSÃO
**Novas Funcionalidades**:
- ✅ **Aba de Usuários** unificada (Barbeiros + Clientes)
  - Navegação interna com TabBar
  - **Nova aba de Clientes** com busca avançada
  - Detalhes completos de cada cliente
  - Exclusão com confirmação
- ✅ **Aba de Agendamentos** com filtros avançados (status, data, barbeiro, cliente)
- ✅ **Filtros de Período** no Dashboard (Hoje, Semana, Mês, Tudo)
- ✅ **Configurações Avançadas**:
  - Backup de dados
  - Limpar cache
  - **Resetar banco de dados** (com senha e confirmação dupla)
- ✅ **Melhorias na aba Configurações**:
  - Seção "Ações Rápidas"
  - Seção "Zona de Perigo"
  - Estatísticas do admin

**Melhorias**:
- 📊 Dashboard agora mostra período selecionado
- 🎨 UI/UX aprimorado nas configurações
- 👥 Gerenciamento centralizado de usuários (Barbeiros + Clientes)
- 🔒 Maior segurança nas ações críticas
- 📱 Bottom navigation com 5 abas (adicionada "Agendamentos")

### v1.0.0 (29/10/2025)
- Lançamento inicial
- Autenticação completa
- CRUD barbeiros e serviços
- Sistema de agendamentos básico
- Validação em tempo real

## 👥 Contribuidores

- Desenvolvedor Principal

## 📄 Licença

Este projeto está sob a licença MIT.

## 🆘 Suporte

Para dúvidas e suporte:
- Email: suporte@barbearia.com
- Issues: GitHub Issues

---

**Desenvolvido com ❤️ e Flutter**
