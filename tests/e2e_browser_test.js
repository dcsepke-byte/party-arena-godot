// E2E: prüft fliegenden Würfel + Shop/Rucksack-Button.
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ headless: true, executablePath: '/opt/hermes/.playwright/chromium_headless_shell-1228/chrome-headless-shell-linux64/chrome-headless-shell', args: ['--no-sandbox','--disable-gpu','--use-gl=swiftshader','--enable-unsafe-swiftshader','--disable-dev-shm-usage','--max_old_space_size=512'] });
  const context = await browser.newContext({ viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true });
  const page = await context.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(e.message));
  await page.goto('https://dcsepke-byte.github.io/party-arena-godot/', { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForTimeout(9000);
  await page.screenshot({ path: '/opt/data/feat_board.png' });
  const c = await page.$('canvas');
  const box = await c.boundingBox();
  // Würfeln (fliegender Würfel sollte erscheinen)
  await page.touchscreen.tap(box.x + box.width/2, box.y + box.height/2);
  await page.waitForTimeout(600); // während des Flugs
  await page.screenshot({ path: '/opt/data/feat_dice_flying.png' });
  await page.waitForTimeout(1500);
  await page.screenshot({ path: '/opt/data/feat_after_roll.png' });
  console.log('JS-Fehler:', JSON.stringify(errs));
  await browser.close();
})();
