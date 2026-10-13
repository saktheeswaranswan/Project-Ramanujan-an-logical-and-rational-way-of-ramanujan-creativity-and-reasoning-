
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;

import java.util.ArrayList;
import java.util.Random;

// ============================================================
// RAMANUJAN PARTITION EXPLORER
// Processing Android Mode
//
// Target slider: 0-200; valid target: 1-200
// Bounded limit slider: 1-200
// Page size: 8
//
// RANDOM PARTITION:
// Selects a uniformly random rank among ordinary partitions
// of n, loads its page and highlights the selected partition.
//
// Does not store every partition in memory.
// ============================================================

final int MAX_N = 200;
final int PAGE_SIZE = 8;

final int BG       = 0xFF101827;
final int PANEL    = 0xFF1B2940;
final int CARD     = 0xFF243650;
final int ACCENT   = 0xFF54D6C5;
final int FG       = 0xFFF3F6FC;
final int MUTED    = 0xFFAAB8CC;
final int SELECTED = 0xFF315B70;

final int ORDINARY = 0;
final int DISTINCT = 1;
final int ODD_PARTS = 2;
final int EVEN_PARTS = 3;
final int BOUNDED = 4;
final int EULER = 5;
final int RAMANUJAN = 6;
final int STATISTICS = 7;
final int CONJUGATE = 8;
final int CONJECTURE = 9;
final int MODE_COUNT = 10;

String[] modeNames = {
  "ORDINARY", "DISTINCT", "ODD PARTS", "EVEN PARTS",
  "BOUNDED", "EULER", "RAMANUJAN", "STATISTICS",
  "CONJUGATE", "CONJECTURE"
};

Random rng = new Random();

int target = 5;
int sliderTarget = 5;
int activeMode = ORDINARY;
int selectedRow = -1;

int boundedLimit = 3;
int sliderBoundedLimit = 3;

String statusText = "Move slider and press GENERATE";

long partitionCount = 0;
long pageIndex = 0;
long totalPages = 1;

long[][] ways = new long[MAX_N + 1][MAX_N + 1];

ArrayList<String> expressions = new ArrayList<String>();
ArrayList<Integer> totals = new ArrayList<Integer>();

int[] allowedParts = new int[MAX_N + 1];
int allowedCount = 0;
boolean distinctMode = false;
int currentPageRows = 0;

int[] selectedTerms = new int[MAX_N + 1];
int selectedLength = 0;

// Layout
float margin, ui;
float inputY, inputH, actionY, actionH;
float modeY, modeW, modeH, modeGap;
float resultTop, resultBottom;
float equationY, equationH, navY, navH;
float listTop, listBottom, rowHeight;

float sliderPanelY, sliderPanelH;
float targetSliderY, boundedSliderY;
float sliderTrackLeft, sliderTrackRight;
float checkX, checkY, checkW, checkH;

boolean draggingTarget = false;
boolean draggingBounded = false;

// ============================================================
// SETUP
// ============================================================

void settings() {
  fullScreen();
}

void setup() {
  orientation(PORTRAIT);
  textFont(createFont("SansSerif", 16));
  calculatePartitionTable();
  calculateLayout();
  generateMode(ORDINARY, 5);
}

// ============================================================
// RESPONSIVE LAYOUT
// ============================================================

void calculateLayout() {
  margin = max(9, min(16, width * 0.035));
  ui = constrain(height / 1100.0, 0.72, 1.0);

  inputY = 105 * ui;
  inputH = 54 * ui;
  actionY = inputY + inputH + 6 * ui;
  actionH = 32 * ui;

  modeY = actionY + actionH + 6 * ui;
  modeGap = 4 * ui;
  modeH = 24 * ui;
  modeW = (width - 2 * margin - 3 * modeGap) / 4.0;

  resultTop = modeY + 3 * modeH + 15 * ui;

  sliderPanelH = 128 * ui;
  sliderPanelY = height - sliderPanelH - 10 * ui;
  resultBottom = sliderPanelY - 7 * ui;

  equationY = resultTop + 41 * ui;
  equationH = 29 * ui;
  navY = resultTop + 75 * ui;
  navH = 21 * ui;

  listTop = navY + navH + 5 * ui;
  listBottom = resultBottom - 6 * ui;

  float available = max(1, listBottom - listTop);
  rowHeight = min(27 * ui, available / PAGE_SIZE);
  rowHeight = max(12, rowHeight);

  sliderTrackLeft = margin + 15 * ui;
  sliderTrackRight = width - margin - 15 * ui;

  targetSliderY = sliderPanelY + 32 * ui;
  boundedSliderY = sliderPanelY + 69 * ui;

  checkW = 130 * ui;
  checkH = 25 * ui;
  checkX = width - margin - checkW;
  checkY = sliderPanelY + 94 * ui;
}

// ============================================================
// PARTITION DP
// ways[m][s] counts partitions of s with parts <= m.
// ============================================================

void calculatePartitionTable() {
  for (int m = 0; m <= MAX_N; m++) {
    ways[m][0] = 1;
  }

  for (int m = 1; m <= MAX_N; m++) {
    for (int s = 1; s <= MAX_N; s++) {
      ways[m][s] = ways[m - 1][s];

      if (s >= m) {
        ways[m][s] += ways[m][s - m];
      }
    }
  }
}

// ============================================================
// DRAW LOOP
// ============================================================

void draw() {
  calculateLayout();
  background(BG);

  drawHeader();
  drawTargetCard();
  drawMainButtons();
  drawModeButtons();
  drawResults();
  drawSliderPanel();
  drawFooter();
}

void drawHeader() {
  textAlign(LEFT, CENTER);

  fill(ACCENT);
  textSize(10 * ui);
  text("NUMBER THEORY LAB", margin, 13 * ui);

  fill(FG);
  textSize(22 * ui);
  text("RAMANUJAN", margin, 39 * ui);

  textSize(15 * ui);
  text("PARTITION EXPLORER", margin, 62 * ui);

  fill(MUTED);
  textSize(9 * ui);
  text("Exact counts | Random rank generation", margin, 83 * ui);
}

void drawTargetCard() {
  noStroke();
  fill(PANEL);
  rect(margin, inputY, width - 2 * margin, inputH, 9 * ui);

  fill(MUTED);
  textAlign(LEFT, CENTER);
  textSize(10 * ui);
  text("TARGET INTEGER", margin + 12 * ui, inputY + 13 * ui);

  fill(FG);
  textSize(21 * ui);
  text(str(sliderTarget), margin + 12 * ui, inputY + 37 * ui);

  fill(ACCENT);
  textAlign(RIGHT, CENTER);
  textSize(10 * ui);
  text("RANGE 0-200", width - margin - 10 * ui, inputY + 37 * ui);

  textAlign(LEFT, CENTER);
}

// ============================================================
// BUTTONS
// Four main buttons: Generate, Random, Copy, Reset
// ============================================================

void drawButton(float x, float y, float w, float h,
                String label, int colour, int labelColour) {
  noStroke();
  fill(colour);
  rect(x, y, w, h, 6 * ui);

  fill(labelColour);
  textAlign(CENTER, CENTER);
  textSize(9 * ui);
  text(fitText(label, w - 5 * ui, 9 * ui), x + w / 2, y + h / 2);

  textAlign(LEFT, CENTER);
}

void drawMainButtons() {
  float gap = 4 * ui;
  float totalW = width - 2 * margin;
  float bw = (totalW - 3 * gap) / 4.0;

  drawButton(margin, actionY, bw, actionH,
             "GENERATE", ACCENT, BG);

  drawButton(margin + bw + gap, actionY, bw, actionH,
             "RANDOM", SELECTED, FG);

  drawButton(margin + 2 * (bw + gap), actionY, bw, actionH,
             "COPY", CARD, FG);

  drawButton(margin + 3 * (bw + gap), actionY, bw, actionH,
             "RESET", CARD, FG);
}

void drawModeButtons() {
  for (int i = 0; i < MODE_COUNT; i++) {
    int r = i / 4;
    int c = i % 4;

    float x = margin + c * (modeW + modeGap);
    float y = modeY + r * (modeH + 4 * ui);

    boolean active = activeMode == i;

    drawButton(x, y, modeW, modeH, modeNames[i],
               active ? ACCENT : CARD,
               active ? BG : FG);
  }
}

// ============================================================
// RESULTS PANEL
// ============================================================

void drawResults() {
  float panelW = width - 2 * margin;

  noStroke();
  fill(PANEL);
  rect(margin, resultTop, panelW,
       max(1, resultBottom - resultTop), 9 * ui);

  fill(FG);
  textAlign(LEFT, CENTER);
  textSize(12 * ui);

  String heading;

  if (activeMode <= BOUNDED) {
    heading = activeMode == DISTINCT
      ? "Distinct partitions = " + partitionCount
      : "p(" + target + ") = " + partitionCount;
  } else {
    heading = modeNames[activeMode] + " | n = " + target;
  }

  text(fitText(heading, panelW - 18 * ui, 12 * ui),
       margin + 10 * ui, resultTop + 13 * ui);

  fill(MUTED);
  textSize(9 * ui);

  String subheading = "METHOD TEST LAB";

  if (activeMode <= BOUNDED) {
    subheading = "PAGE " + (pageIndex + 1) + " / " + totalPages;

    if (activeMode == DISTINCT) {
      subheading += " | MIN " + minimumDistinctParts(target);
      subheading += " | MAX " + maximumDistinctParts(target);
    }

    if (activeMode == BOUNDED) {
      subheading += " | PARTS <= " + boundedLimit;
    }
  }

  text(fitText(subheading, panelW - 18 * ui, 9 * ui),
       margin + 10 * ui, resultTop + 29 * ui);

  drawEquation(margin + 7 * ui, equationY,
               panelW - 14 * ui, equationH);

  if (activeMode <= BOUNDED) {
    drawPageNavigation(panelW);
    drawPartitionRows(panelW);
  } else {
    drawMethodReport(panelW);
    drawMethodNavigation(panelW);
  }
}

void drawEquation(float x, float y, float w, float h) {
  noStroke();
  fill(SELECTED);
  rect(x, y, w, h, 5 * ui);

  String s = "Tap a partition row to inspect its sum";

  if (selectedRow >= 0 && selectedRow < expressions.size()) {
    s = expressions.get(selectedRow) + " = " + totals.get(selectedRow);
  }

  fill(FG);
  textAlign(LEFT, CENTER);
  textSize(10 * ui);
  text(fitText(s, w - 14 * ui, 10 * ui), x + 7 * ui, y + h / 2);
}

void drawPageNavigation(float panelW) {
  float x = margin + 7 * ui;
  float gap = 4 * ui;
  float w = (panelW - 14 * ui - 2 * gap) / 3.0;

  drawButton(x, navY, w, navH, "PREVIOUS",
             pageIndex > 0 ? CARD : PANEL,
             pageIndex > 0 ? FG : MUTED);

  drawButton(x + w + gap, navY, w, navH, "NEXT PAGE",
             pageIndex + 1 < totalPages ? ACCENT : PANEL,
             pageIndex + 1 < totalPages ? BG : MUTED);

  drawButton(x + 2 * (w + gap), navY, w, navH, "LAST PAGE",
             pageIndex + 1 < totalPages ? SELECTED : PANEL,
             pageIndex + 1 < totalPages ? ACCENT : MUTED);
}

int visibleRows() {
  if (rowHeight <= 0) return 0;

  int capacity = (int)Math.floor(max(0, listBottom - listTop) / rowHeight);

  return Math.max(0, Math.min(PAGE_SIZE,
         Math.min(currentPageRows, capacity)));
}

void drawPartitionRows(float panelW) {
  int count = visibleRows();

  for (int i = 0; i < count; i++) {
    float x = margin + 7 * ui;
    float y = listTop + i * rowHeight;
    float w = panelW - 14 * ui;

    noStroke();
    fill(i == selectedRow ? SELECTED : (i % 2 == 0 ? CARD : PANEL));
    rect(x, y + 1, w, max(1, rowHeight - 2), 4 * ui);

    fill(i == selectedRow ? ACCENT : MUTED);
    textAlign(LEFT, CENTER);
    textSize(8 * ui);
    text((pageIndex * PAGE_SIZE + i + 1) + ".", x + 4 * ui,
         y + rowHeight / 2);

    fill(FG);
    textSize(10 * ui);
    float expressionX = x + 30 * ui;
    float expressionW = w - 78 * ui;

    text(fitText(expressions.get(i), expressionW, 10 * ui),
         expressionX, y + rowHeight / 2);

    fill(ACCENT);
    textAlign(RIGHT, CENTER);
    textSize(9 * ui);
    text("=" + totals.get(i), x + w - 5 * ui, y + rowHeight / 2);
  }

  textAlign(LEFT, CENTER);
}

// ============================================================
// METHOD REPORTS
// ============================================================

void drawMethodReport(float panelW) {
  ArrayList<String> report = getMethodReport();

  float x = margin + 10 * ui;
  float y = listTop;
  float lineH = 19 * ui;
  float bottom = listBottom - 30 * ui;

  fill(FG);
  textAlign(LEFT, TOP);
  textSize(10 * ui);

  for (int i = 0; i < report.size(); i++) {
    float yy = y + i * lineH;
    if (yy + lineH > bottom) break;

    text(fitText(report.get(i), panelW - 20 * ui, 10 * ui), x, yy);
  }

  textAlign(LEFT, CENTER);
}

void drawMethodNavigation(float panelW) {
  float h = 24 * ui;

  drawButton(margin + 7 * ui, listBottom - h,
             panelW - 14 * ui, h,
             "NEXT TEST / METHOD", ACCENT, BG);
}

ArrayList<String> getMethodReport() {
  ArrayList<String> r = new ArrayList<String>();

  if (activeMode == EULER) {
    long ep = eulerPartition(target);

    r.add("Euler pentagonal-number recurrence");
    r.add("Generalized pentagonal numbers: 1, 2, 5, 7...");
    r.add("Euler recurrence: " + ep);
    r.add("Dynamic programming: " + ways[target][target]);
    r.add("Verification: " + (ep == ways[target][target] ? "PASS" : "FAIL"));
  } else if (activeMode == RAMANUJAN) {
    r.add("Ramanujan partition congruences");
    r.add("p(5k+4) divisible by 5");
    r.add("p(7k+5) divisible by 7");
    r.add("p(11k+6) divisible by 11");

    boolean found = false;

    if (target % 5 == 4) {
      r.add("p(n) mod 5 = " + (ways[target][target] % 5));
      found = true;
    }
    if (target % 7 == 5) {
      r.add("p(n) mod 7 = " + (ways[target][target] % 7));
      found = true;
    }
    if (target % 11 == 6) {
      r.add("p(n) mod 11 = " + (ways[target][target] % 11));
      found = true;
    }
    if (!found) r.add("Target outside these residue classes.");
  } else if (activeMode == STATISTICS) {
    r.add("Partition statistics");

    if (selectedLength == 0) {
      r.add("Select an ORDINARY partition row first.");
    } else {
      int odd = 0, even = 0, ones = 0;

      for (int i = 0; i < selectedLength; i++) {
        if (selectedTerms[i] % 2 == 0) even++;
        else odd++;
        if (selectedTerms[i] == 1) ones++;
      }

      r.add("Number of parts: " + selectedLength);
      r.add("Largest part: " + selectedTerms[0]);
      r.add("Smallest part: " + selectedTerms[selectedLength - 1]);
      r.add("Odd parts: " + odd);
      r.add("Even parts: " + even);
      r.add("Number of ones: " + ones);
      r.add("Largest minus length: " + (selectedTerms[0] - selectedLength));
      r.add("Mex: " + calculateMex(selectedTerms, selectedLength));
      r.add("Conjugate: " + conjugateString(selectedTerms, selectedLength));
    }
  } else if (activeMode == CONJUGATE) {
    r.add("Ferrers diagram / partition conjugation");

    if (selectedLength == 0) {
      r.add("Select an ORDINARY partition row first.");
      r.add("Example: (3,2) -> (2,2,1)");
    } else {
      r.add("Original: " + termsToString(selectedTerms, selectedLength));
      r.add("Conjugate: " + conjugateString(selectedTerms, selectedLength));
      r.add("The conjugate has the same sum.");
    }
  } else if (activeMode == CONJECTURE) {
    long d = countRestricted(target, DISTINCT, target);
    long o = countRestricted(target, ODD_PARTS, target);

    r.add("Euler odd/distinct partition identity");
    r.add("Target: " + target);
    r.add("Distinct-part count: " + d);
    r.add("Odd-part count: " + o);
    r.add("Equality test: " + (d == o ? "PASS" : "FAIL"));
    r.add("Finite testing is not a proof.");
  }

  return r;
}

// ============================================================
// DISTINCT STATISTICS
// ============================================================

int minimumDistinctParts(int n) {
  return n >= 1 ? 1 : 0;
}

int maximumDistinctParts(int n) {
  int k = 0;
  int sum = 0;

  while (sum + k + 1 <= n) {
    k++;
    sum += k;
  }

  return k;
}

// ============================================================
// RESTRICTED PARTITION DP
// ============================================================

void buildAllowedParts(int n, int mode, int limit) {
  allowedCount = 0;
  distinctMode = mode == DISTINCT;

  for (int v = 1; v <= n; v++) {
    boolean allow = true;

    if (mode == ODD_PARTS && v % 2 == 0) allow = false;
    if (mode == EVEN_PARTS && v % 2 != 0) allow = false;
    if (mode == BOUNDED && v > limit) allow = false;

    if (allow) allowedParts[++allowedCount] = v;
  }
}

long[][] buildRestrictedDP(int n, boolean distinct) {
  long[][] dp = new long[allowedCount + 1][n + 1];

  for (int i = 0; i <= allowedCount; i++) dp[i][0] = 1;

  for (int i = 1; i <= allowedCount; i++) {
    int v = allowedParts[i];

    for (int s = 1; s <= n; s++) {
      dp[i][s] = dp[i - 1][s];

      if (s >= v) {
        if (distinct) dp[i][s] += dp[i - 1][s - v];
        else dp[i][s] += dp[i][s - v];
      }
    }
  }

  return dp;
}

// ============================================================
// GENERATE MODE
// ============================================================

void generateMode(int mode, int n) {
  if (n < 1 || n > MAX_N) {
    statusText = "Select a target from 1 to 200";
    return;
  }

  target = n;
  sliderTarget = n;
  activeMode = mode;
  pageIndex = 0;
  selectedRow = -1;
  selectedLength = 0;

  expressions.clear();
  totals.clear();
  currentPageRows = 0;

  if (mode <= BOUNDED) {
    buildAllowedParts(target, mode, boundedLimit);

    long[][] dp = buildRestrictedDP(target, distinctMode);
    partitionCount = dp[allowedCount][target];

    totalPages = Math.max(
      1L, (partitionCount + PAGE_SIZE - 1) / PAGE_SIZE
    );

    loadRestrictedPage(dp);
    statusText = modeNames[mode] + " generated: n = " + target;
  } else {
    partitionCount = ways[target][target];
    totalPages = 1;
    statusText = modeNames[mode] + " ready: n = " + target;
  }
}

void loadRestrictedPage(long[][] dp) {
  expressions.clear();
  totals.clear();
  selectedRow = -1;

  long startRank = pageIndex * PAGE_SIZE;

  currentPageRows = (int)Math.max(
    0L, Math.min((long)PAGE_SIZE, partitionCount - startRank)
  );

  for (int i = 0; i < currentPageRows; i++) {
    int[] terms = new int[target];

    int len = unrankRestricted(
      target, allowedCount, startRank + i,
      distinctMode, dp, terms, 0
    );

    expressions.add(termsToString(terms, len));

    int sum = 0;
    for (int j = 0; j < len; j++) sum += terms[j];
    totals.add(sum);
  }
}

int unrankRestricted(int remaining, int maxIndex, long rank,
                     boolean distinct, long[][] dp,
                     int[] terms, int depth) {
  if (remaining == 0) return depth;

  for (int i = maxIndex; i >= 1; i--) {
    int v = allowedParts[i];
    if (v > remaining) continue;

    int nextIndex = distinct ? i - 1 : i;
    long branchCount = dp[nextIndex][remaining - v];

    if (rank >= branchCount) {
      rank -= branchCount;
      continue;
    }

    terms[depth] = v;

    return unrankRestricted(
      remaining - v, nextIndex, rank, distinct,
      dp, terms, depth + 1
    );
  }

  return depth;
}

// ============================================================
// RANDOM ORDINARY PARTITION
// ============================================================

// Returns a random integer in [0, bound), including bounds
// larger than Integer.MAX_VALUE. Uses rejection sampling.
long randomLongBelow(long bound) {
  if (bound <= 0) return 0;

  long mask = bound - 1;
  long bits;
  long value;

  do {
    bits = rng.nextLong() >>> 1;

    if ((bound & mask) == 0) {
      return bits & mask;
    }

    value = bits % bound;
  } while (bits - value + mask < 0L);

  return value;
}

void randomPartition() {
  if (sliderTarget < 1 || sliderTarget > MAX_N) {
    statusText = "Choose a target from 1 to 200 first";
    return;
  }

  int n = sliderTarget;

  // Random button specifically selects an ordinary partition.
  activeMode = ORDINARY;
  target = n;
  sliderTarget = n;

  // p(n) is safely represented by long for n <= 200.
  long count = ways[n][n];

  if (count <= 0) {
    statusText = "No partitions available for this target";
    return;
  }

  long rank = randomLongBelow(count);

  // Convert the random rank to a page and row.
  pageIndex = rank / PAGE_SIZE;
  int row = (int)(rank % PAGE_SIZE);

  generateMode(ORDINARY, n);

  // generateMode resets to the first page; restore random page.
  pageIndex = rank / PAGE_SIZE;

  buildAllowedParts(n, ORDINARY, boundedLimit);
  long[][] dp = buildRestrictedDP(n, false);
  loadRestrictedPage(dp);

  if (row >= 0 && row < expressions.size()) {
    selectedRow = row;
    preserveSelectedPartition();

    int actualSum = totals.get(row);
    statusText = "Random partition " + (rank + 1) + " of " + count
      + ": " + expressions.get(row) + " = " + actualSum;
  } else {
    statusText = "Random partition page loaded";
  }
}

// ============================================================
// PAGE NAVIGATION
// ============================================================

void reloadCurrentPage() {
  if (activeMode > BOUNDED) return;

  buildAllowedParts(target, activeMode, boundedLimit);
  long[][] dp = buildRestrictedDP(target, distinctMode);
  loadRestrictedPage(dp);
}

void previousPage() {
  if (pageIndex <= 0) {
    statusText = "Already on the first page";
    return;
  }

  pageIndex--;
  reloadCurrentPage();
}

void nextPage() {
  if (pageIndex + 1 >= totalPages) {
    statusText = "Already on the last page";
    return;
  }

  pageIndex++;
  reloadCurrentPage();
}

void lastPage() {
  if (totalPages <= 0) return;

  pageIndex = totalPages - 1;
  reloadCurrentPage();
  statusText = "Last page loaded";
}

void nextMethodTest() {
  if (activeMode >= EULER) {
    int n = target < MAX_N ? target + 1 : 1;
    generateMode(activeMode, n);
  } else {
    int next = activeMode + 1;
    if (next > BOUNDED) next = ORDINARY;
    generateMode(next, target);
  }
}

// ============================================================
// EULER PENTAGONAL RECURRENCE
// ============================================================

long eulerPartition(int n) {
  long[] p = new long[n + 1];
  p[0] = 1;

  for (int m = 1; m <= n; m++) {
    long sum = 0;

    for (int k = 1; ; k++) {
      int g1 = k * (3 * k - 1) / 2;
      int g2 = k * (3 * k + 1) / 2;

      if (g1 > m) break;

      int sign = (k % 2 == 1) ? 1 : -1;
      sum += sign * p[m - g1];

      if (g2 <= m) sum += sign * p[m - g2];
    }

    p[m] = sum;
  }

  return p[n];
}

long countRestricted(int n, int mode, int limit) {
  buildAllowedParts(n, mode, limit);
  long[][] dp = buildRestrictedDP(n, mode == DISTINCT);
  return dp[allowedCount][n];
}

// ============================================================
// PARTITION UTILITIES
// ============================================================

String termsToString(int[] terms, int len) {
  StringBuilder b = new StringBuilder();

  for (int i = 0; i < len; i++) {
    if (i > 0) b.append(" + ");
    b.append(terms[i]);
  }

  return b.toString();
}

int calculateMex(int[] terms, int len) {
  boolean[] seen = new boolean[MAX_N + 2];

  for (int i = 0; i < len; i++) {
    int v = terms[i];
    if (v >= 1 && v < seen.length) seen[v] = true;
  }

  for (int i = 1; i < seen.length; i++) {
    if (!seen[i]) return i;
  }

  return seen.length;
}

String conjugateString(int[] terms, int len) {
  if (len <= 0) return "(none)";

  int largest = terms[0];
  StringBuilder b = new StringBuilder();

  for (int col = 1; col <= largest; col++) {
    int count = 0;

    for (int i = 0; i < len; i++) {
      if (terms[i] >= col) count++;
    }

    if (count > 0) {
      if (b.length() > 0) b.append(" + ");
      b.append(count);
    }
  }

  return b.toString();
}

void preserveSelectedPartition() {
  selectedLength = 0;

  if (selectedRow < 0 || selectedRow >= expressions.size()) return;

  String[] parts = split(expressions.get(selectedRow), " + ");

  for (int i = 0; i < parts.length && i < selectedTerms.length; i++) {
    selectedTerms[i] = Integer.parseInt(parts[i].trim());
  }

  selectedLength = parts.length;
}

// ============================================================
// MODE SELECTION
// ============================================================

void selectMode(int mode) {
  preserveSelectedPartition();

  if (mode <= BOUNDED) {
    generateMode(mode, target);
  } else {
    activeMode = mode;
    selectedRow = -1;
    statusText = modeNames[mode] + " selected";
  }
}

// ============================================================
// SLIDERS
// ============================================================

float valueToX(int value) {
  return map(constrain(value, 0, MAX_N), 0, MAX_N,
             sliderTrackLeft, sliderTrackRight);
}

int xToValue(float x) {
  float v = map(constrain(x, sliderTrackLeft, sliderTrackRight),
                sliderTrackLeft, sliderTrackRight, 0, MAX_N);
  return constrain(round(v), 0, MAX_N);
}

void drawSliderPanel() {
  noStroke();
  fill(PANEL);
  rect(margin, sliderPanelY, width - 2 * margin,
       sliderPanelH, 9 * ui);

  fill(FG);
  textAlign(LEFT, CENTER);
  textSize(10 * ui);
  text("TARGET: " + sliderTarget,
       margin + 10 * ui, sliderPanelY + 12 * ui);

  drawSlider(targetSliderY, sliderTarget);

  fill(FG);
  textSize(9 * ui);
  text("BOUNDED LIMIT: " + sliderBoundedLimit,
       margin + 10 * ui, sliderPanelY + 49 * ui);

  drawSlider(boundedSliderY, sliderBoundedLimit);

  drawButton(checkX, checkY, checkW, checkH,
             "CHECK / GENERATE", ACCENT, BG);

  fill(MUTED);
  textSize(8 * ui);
  textAlign(LEFT, CENTER);
  text("Slide to choose a value",
       margin + 10 * ui, sliderPanelY + 105 * ui);
}

void drawSlider(float y, int value) {
  float x1 = sliderTrackLeft;
  float x2 = sliderTrackRight;
  float knob = valueToX(value);

  stroke(CARD);
  strokeWeight(5 * ui);
  line(x1, y, x2, y);

  stroke(ACCENT);
  line(x1, y, knob, y);

  noStroke();
  fill(ACCENT);
  ellipse(knob, y, 14 * ui, 14 * ui);

  fill(MUTED);
  textSize(7.5 * ui);
  textAlign(LEFT, CENTER);
  text("0", x1, y + 10 * ui);

  textAlign(RIGHT, CENTER);
  text("200", x2, y + 10 * ui);

  textAlign(LEFT, CENTER);
}

// ============================================================
// FOOTER
// ============================================================

void drawFooter() {
  fill(MUTED);
  textAlign(CENTER, CENTER);
  textSize(8 * ui);

  text(fitText(statusText, width - 2 * margin, 8 * ui),
       width / 2, height - 4 * ui);

  textAlign(LEFT, CENTER);
}

String fitText(String value, float maxWidth, float size) {
  textSize(size);

  if (maxWidth <= 0) return "";
  if (textWidth(value) <= maxWidth) return value;

  String s = value;

  while (s.length() > 0 && textWidth(s + "...") > maxWidth) {
    s = s.substring(0, s.length() - 1);
  }

  return s + "...";
}

// ============================================================
// GENERATE / RESET / COPY
// ============================================================

void checkGenerate() {
  if (sliderTarget < 1 || sliderTarget > MAX_N) {
    statusText = "Choose a target from 1 to 200";
    return;
  }

  boundedLimit = constrain(sliderBoundedLimit, 1, MAX_N);
  generateMode(activeMode, sliderTarget);
}

void resetApp() {
  sliderTarget = 5;
  sliderBoundedLimit = 3;
  boundedLimit = 3;
  selectedRow = -1;
  selectedLength = 0;

  generateMode(ORDINARY, 5);
  statusText = "Reset complete";
}

void copyCurrentPage() {
  try {
    StringBuilder out = new StringBuilder();

    out.append("RAMANUJAN PARTITION EXPLORER\n");
    out.append("Target: ").append(target).append("\n");
    out.append("Mode: ").append(modeNames[activeMode]).append("\n");

    if (activeMode <= BOUNDED) {
      out.append("Count: ").append(partitionCount).append("\n");
      out.append("Page: ").append(pageIndex + 1)
         .append(" / ").append(totalPages).append("\n");

      if (activeMode == BOUNDED) {
        out.append("Bounded limit: ").append(boundedLimit).append("\n");
      }

      if (activeMode == DISTINCT) {
        out.append("Minimum parts: ")
           .append(minimumDistinctParts(target)).append("\n");
        out.append("Maximum parts: ")
           .append(maximumDistinctParts(target)).append("\n");
      }

      for (int i = 0; i < expressions.size(); i++) {
        out.append(pageIndex * PAGE_SIZE + i + 1)
           .append(". ").append(expressions.get(i))
           .append(" = ").append(totals.get(i)).append("\n");
      }
    } else {
      ArrayList<String> report = getMethodReport();

      for (int i = 0; i < report.size(); i++) {
        out.append(report.get(i)).append("\n");
      }
    }

    Context context = getActivity();

    if (context == null) {
      statusText = "Clipboard unavailable";
      return;
    }

    ClipboardManager cb = (ClipboardManager)
      context.getSystemService(Context.CLIPBOARD_SERVICE);

    if (cb == null) {
      statusText = "Clipboard unavailable";
      return;
    }

    cb.setPrimaryClip(
      ClipData.newPlainText("Partition Explorer", out.toString())
    );

    statusText = "Copied to clipboard";
  } catch (Exception e) {
    statusText = "Copy failed: " + e.getClass().getSimpleName();
  }
}

// ============================================================
// TOUCH HANDLING
// ============================================================

boolean isNearSlider(float x, float y, float sliderY) {
  return x >= sliderTrackLeft - 12 * ui &&
         x <= sliderTrackRight + 12 * ui &&
         abs(y - sliderY) <= 12 * ui;
}

void mousePressed() {
  calculateLayout();

  draggingTarget = false;
  draggingBounded = false;

  if (isNearSlider(mouseX, mouseY, targetSliderY)) {
    draggingTarget = true;
    updateTargetSlider(mouseX);
    return;
  }

  if (isNearSlider(mouseX, mouseY, boundedSliderY)) {
    draggingBounded = true;
    updateBoundedSlider(mouseX);
  }
}

void mouseDragged() {
  calculateLayout();

  if (draggingTarget) {
    updateTargetSlider(mouseX);
  } else if (draggingBounded) {
    updateBoundedSlider(mouseX);
  }
}

void mouseReleased() {
  calculateLayout();

  if (draggingTarget || draggingBounded) {
    if (draggingTarget) updateTargetSlider(mouseX);
    if (draggingBounded) updateBoundedSlider(mouseX);

    draggingTarget = false;
    draggingBounded = false;
    return;
  }

  handleTouch(mouseX, mouseY);
}

void updateTargetSlider(float x) {
  sliderTarget = xToValue(x);
  statusText = "Target " + sliderTarget + " selected; press GENERATE";
}

void updateBoundedSlider(float x) {
  sliderBoundedLimit = max(1, xToValue(x));
  boundedLimit = sliderBoundedLimit;
  statusText = "Bounded limit " + boundedLimit + " selected";
}

void handleTouch(float x, float y) {
  float gap = 4 * ui;
  float totalW = width - 2 * margin;
  float bw = (totalW - 3 * gap) / 4.0;

  // Four main buttons.
  if (y >= actionY && y <= actionY + actionH) {
    if (x >= margin && x <= margin + bw) {
      checkGenerate();
    } else if (x >= margin + bw + gap &&
               x <= margin + 2 * bw + gap) {
      randomPartition();
    } else if (x >= margin + 2 * (bw + gap) &&
               x <= margin + 3 * bw + 2 * gap) {
      copyCurrentPage();
    } else if (x >= margin + 3 * (bw + gap) &&
               x <= margin + 4 * bw + 3 * gap) {
      resetApp();
    }
    return;
  }

  // Method buttons.
  for (int i = 0; i < MODE_COUNT; i++) {
    int r = i / 4;
    int c = i % 4;

    float bx = margin + c * (modeW + modeGap);
    float by = modeY + r * (modeH + 4 * ui);

    if (x >= bx && x <= bx + modeW &&
        y >= by && y <= by + modeH) {
      selectMode(i);
      return;
    }
  }

  // Slider-panel generate button.
  if (x >= checkX && x <= checkX + checkW &&
      y >= checkY && y <= checkY + checkH) {
    checkGenerate();
    return;
  }

  if (y >= sliderPanelY) return;

  // Page navigation.
  if (activeMode <= BOUNDED &&
      y >= navY && y <= navY + navH) {

    float panelW = width - 2 * margin;
    float leftX = margin + 7 * ui;
    float navGap = 4 * ui;
    float navW = (panelW - 14 * ui - 2 * navGap) / 3.0;

    if (x >= leftX && x <= leftX + navW) {
      previousPage();
    } else if (x >= leftX + navW + navGap &&
               x <= leftX + 2 * navW + navGap) {
      nextPage();
    } else if (x >= leftX + 2 * (navW + navGap) &&
               x <= leftX + 3 * navW + 2 * navGap) {
      lastPage();
    }
    return;
  }

  // Analysis mode next-test button.
  float methodH = 24 * ui;
  float methodY = listBottom - methodH;

  if (activeMode > BOUNDED &&
      y >= methodY && y <= methodY + methodH) {
    nextMethodTest();
    return;
  }

  // Visible partition rows only.
  if (activeMode <= BOUNDED &&
      y >= listTop && y < listBottom && rowHeight > 0) {

    int index = (int)Math.floor((y - listTop) / rowHeight);

    if (index >= 0 && index < visibleRows() &&
        index < expressions.size()) {
      selectedRow = index;
      preserveSelectedPartition();

      statusText = expressions.get(index) + " = " + totals.get(index);
    }
  }
}
