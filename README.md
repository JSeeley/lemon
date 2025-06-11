# 🍋 Lemon – AI Travel Planner

Lemon is a mobile application that helps users plan end-to-end travel itineraries with the power of generative AI.

*Example: "I want to go to France in July" ➜ Lemon returns a full itinerary with flights, hotels, dinners and activities.*

---

## Monorepo Layout

```
.
├── ios/                # SwiftUI iPhone application
│   ├── LemonApp.swift
│   ├── ContentView.swift
│   └── …
├── backend/            # Serverless API deployed to Vercel
│   ├── api/plan.js     # OpenAI-powered itinerary endpoint
│   ├── package.json
│   ├── vercel.json
│   └── …
├── .gitignore
└── README.md
```

### iOS App (SwiftUI)
1. Open the `ios` folder in Xcode (`open ios` from Terminal or double-click in Finder).
2. Run on the simulator or a physical device (`⌘R`).
3. The app ships with a stub UI and a `TripPlannerService` that calls the backend.

### Backend (Node.js on Vercel)
1. `cd backend`
2. `npm install`
3. Copy `.env.example` ➜ `.env` and add your **OpenAI** key.
   ```
   cp .env.example .env
   ```
4. Run locally with the Vercel dev server:
   ```
   npx vercel dev
   ```
5. Deploy: `vercel --prod`

### Environment Variables
| Variable | Description |
|----------|-------------|
| `OPENAI_API_KEY` | Secret key from <https://platform.openai.com/> |

### Roadmap
- [ ] Flight and hotel search integrations
- [ ] Calendar & wallet export
- [ ] Collaborative trip planning

### Contributing
Pull requests are welcome! Please open an issue first to discuss major changes.

---
© 2025 Lemon 🍋 