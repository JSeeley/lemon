# 🍋 Lemon - AI Travel Planning App

Lemon is an intelligent travel planning iOS app that helps users create personalized trip itineraries using AI. Simply tell Lemon where you want to go, and it will generate a complete travel plan including accommodations, activities, dining recommendations, and transportation tips.

## 🌟 Features

- **AI-Powered Itinerary Generation**: Uses ChatGPT to create detailed, personalized travel plans
- **Beautiful iOS Interface**: Native SwiftUI app with a modern, intuitive design
- **Smart Recommendations**: Get suggestions for hotels, restaurants, activities, and transportation
- **Budget Planning**: Receive budget breakdowns and cost estimates
- **Quick Destination Search**: Popular destinations at your fingertips

## 🏗️ Tech Stack

- **iOS App**: Swift, SwiftUI
- **Backend**: Node.js, Express
- **AI**: OpenAI ChatGPT API
- **Deployment**: Vercel (Backend)
- **Design**: Native iOS design with lemon-themed color scheme

## 📁 Project Structure

```
├── LemonApp/                   # iOS Application
│   ├── LemonApp.xcodeproj/    # Xcode project file
│   └── LemonApp/
│       ├── Views/             # SwiftUI views
│       ├── Models/            # Data models
│       ├── ViewModels/        # View models
│       ├── Services/          # API and other services
│       └── Resources/         # Assets and resources
├── backend/                    # Node.js Backend
│   ├── api/                   # API endpoints
│   ├── lib/                   # Shared utilities
│   ├── config/                # Configuration files
│   ├── package.json           # Node dependencies
│   └── vercel.json            # Vercel configuration
└── docs/                      # Documentation

```

## 🚀 Getting Started

### Prerequisites

- Xcode 15.0 or later
- iOS 17.0+ deployment target
- Node.js 18.x or later
- npm or yarn
- OpenAI API key
- Vercel account (for deployment)

### Backend Setup

1. **Navigate to the backend directory:**
   ```bash
   cd backend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Create a `.env` file:**
   ```bash
   cp .env.example .env
   ```
   Edit `.env` and add your OpenAI API key:
   ```
   OPENAI_API_KEY=your_openai_api_key_here
   ```

4. **Run the backend locally:**
   ```bash
   npm run dev
   ```
   The API will be available at `http://localhost:3000`

### iOS App Setup

1. **Open the Xcode project:**
   ```bash
   open LemonApp/LemonApp.xcodeproj
   ```

2. **Update the API endpoint:**
   - Open `LemonApp/Services/APIService.swift`
   - Update the `baseURL` to your backend URL:
     - For local development: `http://localhost:3000/api`
     - For production: `https://your-app-name.vercel.app/api`

3. **Build and run:**
   - Select your target device/simulator
   - Press `Cmd + R` to build and run

## 🌐 Deployment

### Backend Deployment (Vercel)

1. **Install Vercel CLI:**
   ```bash
   npm i -g vercel
   ```

2. **Deploy to Vercel:**
   ```bash
   cd backend
   vercel
   ```

3. **Set environment variables:**
   ```bash
   vercel env add OPENAI_API_KEY
   ```

4. **Deploy to production:**
   ```bash
   vercel --prod
   ```

### iOS App Distribution

1. Configure your Apple Developer account in Xcode
2. Update bundle identifier and signing settings
3. Archive and distribute through App Store Connect

## 🔑 API Endpoints

- `GET /api/health` - Health check endpoint
- `POST /api/plan-trip` - Generate trip itinerary
  - Body parameters:
    - `destination` (required): Where to go
    - `duration` (optional): Trip length
    - `preferences` (optional): Travel preferences
    - `budget` (optional): Budget range

## 🎨 Customization

- **Colors**: Modify the color scheme in `ContentView.swift`
- **API Model**: Adjust the ChatGPT prompt in `backend/api/plan-trip.js`
- **UI Components**: Add new views in the `Views` directory

## 📱 App Screenshots

The app features:
- Clean, modern interface with lemon emoji branding
- Intuitive search functionality
- Beautiful gradient backgrounds
- Quick destination suggestions

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- OpenAI for ChatGPT API
- Vercel for serverless hosting
- Apple for SwiftUI framework

---

Made with 🍋 by the Lemon team