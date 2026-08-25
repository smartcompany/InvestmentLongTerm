import storeUrls from './store-urls.mjs';

export default `App Review Notes - My Assets AI
Bundle ID: com.smartcompany.longterminvestment

1) CORE FLOW
- Launch app → bottom tabs include growth race / what-if / my assets / retirement simulation
- "내 자산 관리" (My Assets): add holdings, view chart/returns, optional AI portfolio review and AI trend briefing (ad may show first)
- "그때 샀다면?": pick asset, amount, years ago → optional ad → result chart
- Retirement simulation: cash + holdings → run → result chart
- Growth race: pick assets and period → animated comparison

2) ACCESS / SETUP
- No login or account required
- No payment, subscription, or in-app purchase required
- Reviewer can test core flows without an account

3) PERMISSIONS
- Notifications: optional (local reminders); not required for core flow
- Network: fetches asset prices and AI analysis from our API

4) SERVER / AI
- Price and calculation: https://investment-long-term-server.vercel.app
- AI portfolio / trend endpoints send portfolio snapshot text (not photos) for analysis
- AI output is informational only — not investment advice

5) ADS
- Interstitial ads may appear before some result or AI evaluation screens

Privacy Policy: ${storeUrls.privacyUrl}
Support: ${storeUrls.supportUrl}
`;
