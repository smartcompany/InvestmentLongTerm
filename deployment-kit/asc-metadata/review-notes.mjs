import storeUrls from './store-urls.mjs';

export default `App Review Notes - Time Capital (타임 캐피탈)
Bundle ID: com.smartcompany.longterminvestment

1) CORE FLOW
- Launch app → bottom tabs: Past simulation / Retirement / Growth race / My assets
- Tab 1 "그때 샀다면?": pick asset, amount, years ago → watch ad (if shown) → see investment result chart
- Tab 2 "은퇴 가능할까?": set cash, holdings, withdrawal, inflation → run simulation → result + chart
- Tab 3 "성장률 경주": pick assets and period → animated growth comparison
- Tab 4 "지금 내 자산": preview imported assets → watch ad → manage holdings (add/delete)

2) ACCESS / SETUP
- No login or account required
- No payment, subscription, or in-app purchase required
- Reviewer can fully test all simulation tabs without an account

3) PERMISSIONS
- Notifications: not required for core flow
- Network: fetches asset price data from our API for simulations

4) SERVER USAGE
- Asset price / calculation requests go to https://investment-long-term-server.vercel.app
- No user-uploaded photos or personal content sent to the server

5) ADS
- Interstitial ads may appear before some result screens (simulation results, my assets unlock)

Privacy Policy: ${storeUrls.privacyUrl}
Support: ${storeUrls.supportUrl}
`;
