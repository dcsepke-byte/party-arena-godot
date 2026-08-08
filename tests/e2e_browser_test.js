// E2E-Browser: würfelt und prüft, ob ein Minigame sichtbar startet.
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ headless: true, executablePath: '/opt/hermes/.playwright/chromium_headless_shell-1228/chrome-headless-shell-linux64/chrome-headless-shell', args: ['--no-sandbox','--disable-gpu','--use-gl=swiftshader','--enable-unsafe-swiftshader','--disable-dev-shm-usage','--max_old_space_size=512'] });
  const context = await browser.newContext({ viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true });
  const page = await context.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(e.message));
  await page.goto('https://dcsepke-byte.github.io/party-arena-godot/', { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForTimeout(9000);
  await page.screenshot({ path: '/opt/data/mg_board.png' });
  const c = await page.$('canvas');
  const box = await c.boundingBox();
  // Würfeln
  await page.touchscreen.tap(box.x + box.width/2, box.y + box.height/2);
  await page.waitForTimeout(1500); // Würfeln + Bewegung
  await page.screenshot({ path: '/opt/data/mg_after_roll.png' });
  // Warten bis Minigame (nach Bewegung ~0.4s + start)
  await page.waitForTimeout(2500);
  await page.screenshot({ path: '/opt/data/mg_playing.png' });
  console.log('JS-Fehler:', JSON.stringify(errs));
  await browser.close();
})();
