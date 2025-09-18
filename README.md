# RSID - R&D Tax Credits Management Platform

A modern web application for managing UK R&D Tax Credits applications, built with Ruby on Rails 8 and Svelte 5.

> **⚠️ IMPORTANT: This is a UI/UX mockup codebase**  
> This application is designed for prototyping and user experience validation.  
> The codebase prioritizes rapid development and visual demonstration over production-ready architecture.  
> When building the real application, consider refactoring the large controllers and models into smaller, more focused components.

## 🚀 Features

### Core Functionality
- **R&D Claim Management**: Create, view, edit, and delete R&D claims
- **Expenditure Tracking**: Monitor and categorize R&D expenditures
- **Grant Applications**: Manage grant applications and documentation
- **User Management**: Role-based access control (Admin, Employee, Client)
- **Dashboard Analytics**: Real-time insights and project statistics

### User Roles & Permissions
- **Admins**: Full system access, can view all projects and manage users
- **Employees**: Can manage all projects and assist clients
- **Clients**: Can create, view, edit, and delete their own R&D claims

### Technical Features
- **Modern UI**: Built with Svelte 5 and DaisyUI components
- **Real-time Updates**: Inertia.js for seamless SPA-like experience
- **Responsive Design**: Works on desktop, tablet, and mobile devices
- **Theme Support**: Dark/light mode with customizable themes
- **Form Validation**: Client and server-side validation

## 🛠 Tech Stack

### Backend
- **Ruby on Rails 8.0.2.1**: Modern Rails with latest features
- **SQLite**: Database (configurable for production)
- **Puma**: High-performance web server
- **Inertia Rails**: Connect Rails with modern frontend

### Frontend
- **Svelte 5**: Latest Svelte with runes (`$state`, `$props`, `$bindable`)
- **Tailwind CSS**: Utility-first CSS framework
- **DaisyUI**: Component library built on Tailwind
- **Vite**: Fast build tool and development server

### Development Tools
- **Overmind**: Process manager for development
- **Kamal**: Zero-downtime deployment
- **RuboCop**: Ruby code linting
- **Brakeman**: Security vulnerability scanner

## 📋 Prerequisites

- **Ruby 3.3.6** or higher
- **Node.js 18** or higher
- **Git**

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/joekrucz/RSID.git
cd RSID
```

### 2. Install Dependencies
```bash
# Install Ruby gems
bundle install

# Install Node.js packages
npm install
```

### 3. Setup Database
```bash
# Create and migrate database
bin/rails db:create
bin/rails db:migrate

# Seed with sample data (optional)
bin/rails db:seed
```

### 4. Start Development Server
```bash
# Start all services (Rails + Vite)
bin/dev
```

The application will be available at `http://localhost:3100`

## 🔧 Configuration

### Environment Variables
Create a `.env` file in the root directory:

```env
# Database
DATABASE_URL=sqlite3:db/development.sqlite3

# Rails
RAILS_ENV=development
SECRET_KEY_BASE=your_secret_key_here

# Vite
VITE_RUBY_HOST=localhost
VITE_RUBY_PORT=5173
```

### Database Configuration
The application uses SQLite by default. For production, update `config/database.yml`:

```yaml
production:
  adapter: postgresql
  url: <%= ENV['DATABASE_URL'] %>
```

## 📁 Project Structure

```
RSID/
├── app/
│   ├── controllers/          # Rails controllers
│   ├── models/              # ActiveRecord models
│   ├── frontend/            # Svelte components and pages
│   │   ├── components/      # Reusable Svelte components
│   │   ├── pages/          # Page components
│   │   └── stores/         # Svelte stores
│   └── views/              # Rails views
├── config/                 # Rails configuration
├── db/                     # Database migrations and seeds
├── test/                   # Test files
└── public/                 # Static assets
```

## 🧪 Testing

### Run All Tests
```bash
bin/rails test
```

### Run Specific Test Suites
```bash
# Model tests
bin/rails test:models

# Controller tests
bin/rails test:controllers

# System tests
bin/rails test:system
```

### Code Quality
```bash
# Ruby linting
bin/rubocop

# Security scanning
bin/brakeman
```

## 🚀 Deployment

### Using Kamal (Recommended)
```bash
# Deploy to production
bin/kamal deploy

# Deploy with zero downtime
bin/kamal deploy --rolling
```

### Manual Deployment
1. Set up your production server
2. Configure environment variables
3. Run database migrations
4. Start the application with Puma

## 📊 Database Schema

### Core Models
- **User**: Authentication and role management
- **RndClaim**: R&D claim details
- **RndExpenditure**: Project expenditure tracking
- **GrantApplication**: Grant application management
- **Client**: Client information and relationships

### Key Relationships
- Users can have multiple R&D claims
- R&D claims can have multiple expenditures
- Clients are linked to users with role-based access

## 🔐 Security Features

- **Role-based Access Control**: Granular permissions per user role
- **Session Management**: Secure user sessions
- **Input Validation**: Client and server-side validation
- **SQL Injection Protection**: ActiveRecord parameter binding
- **XSS Protection**: Content Security Policy headers

## 🎨 UI Components

### Built with DaisyUI
- **Cards**: Project and dashboard cards
- **Forms**: Input components with validation
- **Buttons**: Consistent button styling
- **Modals**: Confirmation dialogs
- **Tables**: Data display components

### Theme Support
- **Light Mode**: Default theme
- **Dark Mode**: User-selectable dark theme
- **Customizable**: Easy theme customization

## 🔄 Development Workflow

### Adding New Features
1. Create feature branch: `git checkout -b feature/new-feature`
2. Make changes and test locally
3. Run tests: `bin/rails test`
4. Commit changes: `git commit -m "Add new feature"`
5. Push and create pull request

### Code Style
- Follow Ruby style guide (enforced by RuboCop)
- Use meaningful commit messages
- Write tests for new features
- Update documentation as needed

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue on GitHub
- Check the documentation
- Review existing issues and discussions

## 🔮 Roadmap

### Planned Features
- [ ] Advanced reporting and analytics
- [ ] Document management system
- [ ] Email notifications
- [ ] API endpoints for integrations
- [ ] Mobile app companion
- [ ] Multi-tenant support

### Performance Improvements
- [ ] Database query optimization
- [ ] Caching implementation
- [ ] Asset optimization
- [ ] CDN integration

---

**Built with ❤️ using Ruby on Rails 8 and Svelte 5**
