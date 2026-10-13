
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;

import java.util.Random;
import java.util.Arrays;

// ============================================================
// INTEGER PARTITION EXPLORER
// Processing Android Mode
//
// TARGET: 1 to 200
// PARTITION LENGTH: 1 to target
//
// Examples for target = 5:
// 5
// 4 + 1
// 3 + 2
// 3 + 1 + 1
// 2 + 2 + 1
// 2 + 1 + 1 + 1
// 1 + 1 + 1 + 1 + 1
//
// Features:
// - Direct target slider, 1 to 200
// - Exact number-of-parts slider
// - Random valid partition generation
// - All terms are positive integers
// - Terms are in descending order
// - Sum always equals the selected target
// - Full expression can be copied
//
// This generates random partitions by creating
// positive integer compositions and sorting them.
// It does not uniformly sample distinct partitions.
// ============================================================

final int MAX_N = 200;

final int BG       = 0xFF101827;
final int PANEL    = 0xFF1B2940;
final int CARD     = 0xFF243650;
final int ACCENT   = 0xFF54D6C5;
final int FG       = 0xFFF3F6FC;
final int MUTED    = 0xFFAAB8CC;
final int SELECTED = 0xFF315B70;

Random rng = new Random();

// ============================================================
// STATE
// ============================================================

int target = 200;
int termCount = 5;

int[] terms = new int[MAX_N];
int actualLength = 0;
int actualSum = 0;

String expression = "";
String statusText = "Choose a target and partition length.";

boolean draggingTarget = false;
boolean draggingTerms = false;

// ============================================================
// LAYOUT
// ============================================================

float margin;
float ui;

float headerY;
float targetCardY;
float termsCardY;
float cardH;

float targetTrackY;
float termsTrackY;
float trackLeft;
float trackRight;

float buttonY;
float buttonH;
float resultY;
float resultH;
float footerY;

// ============================================================
// SETTINGS
// ============================================================

void settings() {
  fullScreen();
}

// ============================================================
// SETUP
// ============================================================

void setup() {
  orientation(PORTRAIT);
  textFont(createFont("SansSerif", 16));

  calculateLayout();
  generateRandomPartition();
}

// ============================================================
// LAYOUT CALCULATION
// ============================================================

void calculateLayout() {
  margin = max(10, min(18, width * 0.04));
  ui = constrain(height / 1000.0, 0.72, 1.15);

  headerY = 42 * ui;

  cardH = 76 * ui;

  targetCardY = 88 * ui;
  termsCardY = targetCardY + cardH + 10 * ui;

  targetTrackY = targetCardY + 49 * ui;
  termsTrackY = termsCardY + 49 * ui;

  trackLeft = margin + 18 * ui;
  trackRight = width - margin - 18 * ui;

  buttonY = termsCardY + cardH + 13 * ui;
  buttonH = 42 * ui;

  resultY = buttonY + 2 * buttonH + 20 * ui;
  resultH = max(100, height - resultY - 32 * ui);

  footerY = height - 8 * ui;
}

// ============================================================
// MAIN DRAW
// ============================================================

void draw() {
  calculateLayout();

  background(BG);

  drawHeader();
  drawTargetSlider();
  drawTermSlider();
  drawButtons();
  drawResult();
  drawFooter();
}

// ============================================================
// HEADER
// ============================================================

void drawHeader() {
  textAlign(LEFT, CENTER);

  fill(ACCENT);
  textSize(10 * ui);
  text("NUMBER THEORY LAB", margin, 17 * ui);

  fill(FG);
  textSize(21 * ui);
  text("INTEGER PARTITIONS", margin, 43 * ui);

  fill(MUTED);
  textSize(10 * ui);
  text(
    "Select any integer from 1 to 200",
    margin,
    68 * ui
  );
}

// ============================================================
// SLIDER DRAWING
// ============================================================

void drawSliderCard(
  float y,
  String label,
  String value,
  float trackY,
  float knobX
) {
  noStroke();
  fill(PANEL);

  rect(
    margin,
    y,
    width - 2 * margin,
    cardH,
    9 * ui
  );

  fill(MUTED);
  textAlign(LEFT, CENTER);
  textSize(10 * ui);

  text(
    label,
    margin + 12 * ui,
    y + 17 * ui
  );

  fill(ACCENT);
  textAlign(RIGHT, CENTER);
  textSize(12 * ui);

  text(
    value,
    width - margin - 12 * ui,
    y + 17 * ui
  );

  stroke(CARD);
  strokeWeight(5 * ui);

  line(
    trackLeft,
    trackY,
    trackRight,
    trackY
  );

  stroke(ACCENT);

  line(
    trackLeft,
    trackY,
    knobX,
    trackY
  );

  noStroke();
  fill(ACCENT);

  ellipse(
    knobX,
    trackY,
    17 * ui,
    17 * ui
  );

  textAlign(LEFT, CENTER);
}

// ============================================================
// TARGET SLIDER: 1 TO 200
// ============================================================

float targetToX(int value) {
  return map(
    value,
    1,
    MAX_N,
    trackLeft,
    trackRight
  );
}

int xToTarget(float x) {
  return constrain(
    round(
      map(
        constrain(x, trackLeft, trackRight),
        trackLeft,
        trackRight,
        1,
        MAX_N
      )
    ),
    1,
    MAX_N
  );
}

void drawTargetSlider() {
  drawSliderCard(
    targetCardY,
    "TARGET INTEGER",
    str(target),
    targetTrackY,
    targetToX(target)
  );
}

// ============================================================
// TERM COUNT SLIDER: 1 TO TARGET
// ============================================================

float termsToX(int value) {
  int maximum = max(1, target);

  return map(
    constrain(value, 1, maximum),
    1,
    maximum,
    trackLeft,
    trackRight
  );
}

int xToTerms(float x) {
  int maximum = max(1, target);

  return constrain(
    round(
      map(
        constrain(x, trackLeft, trackRight),
        trackLeft,
        trackRight,
        1,
        maximum
      )
    ),
    1,
    maximum
  );
}

void drawTermSlider() {
  drawSliderCard(
    termsCardY,
    "EXACT NUMBER OF PARTS",
    termCount + " parts",
    termsTrackY,
    termsToX(termCount)
  );

  fill(MUTED);
  textSize(8 * ui);
  textAlign(LEFT, CENTER);

  text("1", trackLeft, termsTrackY + 17 * ui);

  textAlign(RIGHT, CENTER);

  text(
    str(target),
    trackRight,
    termsTrackY + 17 * ui
  );

  textAlign(LEFT, CENTER);
}

// ============================================================
// TARGET UPDATE
// ============================================================

void updateTarget(int newTarget) {
  target = constrain(newTarget, 1, MAX_N);

  // Every part must be at least 1.
  // Therefore the maximum possible part count is target.
  termCount = constrain(
    termCount,
    1,
    target
  );
}

// ============================================================
// RANDOM PARTITION GENERATOR
//
// Creates exactly termCount positive integers
// whose sum equals target.
//
// First allocate 1 to every term.
// Distribute the remaining target-termCount units
// randomly.
// Then sort descending.
// ============================================================

void generateRandomPartition() {
  termCount = constrain(
    termCount,
    1,
    target
  );

  Arrays.fill(terms, 0);

  if (termCount == 1) {
    terms[0] = target;
    actualLength = 1;

  } else {
    for (int i = 0; i < termCount; i++) {
      terms[i] = 1;
    }

    int remaining = target - termCount;

    for (int i = 0; i < remaining; i++) {
      int index = rng.nextInt(termCount);
      terms[index]++;
    }

    actualLength = termCount;
  }

  // Ascending sort followed by reversal.
  Arrays.sort(terms, 0, actualLength);

  for (
    int left = 0, right = actualLength - 1;
    left < right;
    left++, right--
  ) {
    int temp = terms[left];
    terms[left] = terms[right];
    terms[right] = temp;
  }

  expression = termsToString(terms, actualLength);

  actualSum = 0;

  for (int i = 0; i < actualLength; i++) {
    actualSum += terms[i];
  }

  if (
    actualSum == target &&
    actualLength == termCount
  ) {
    statusText =
      "Valid partition: " + actualLength +
      " parts; sum = " + actualSum;
  } else {
    statusText = "Validation error.";
  }
}

// ============================================================
// CONVERT TERMS TO STRING
// ============================================================

String termsToString(int[] values, int length) {
  if (values == null || length <= 0) {
    return "";
  }

  StringBuilder sb = new StringBuilder();

  for (int i = 0; i < length; i++) {
    if (i > 0) {
      sb.append(" + ");
    }

    sb.append(values[i]);
  }

  return sb.toString();
}

// ============================================================
// BUTTONS
// ============================================================

void drawButton(
  float x,
  float y,
  float w,
  float h,
  String label,
  int colour,
  int labelColour
) {
  noStroke();
  fill(colour);

  rect(x, y, w, h, 7 * ui);

  fill(labelColour);
  textAlign(CENTER, CENTER);
  textSize(10 * ui);

  text(
    label,
    x + w / 2,
    y + h / 2
  );

  textAlign(LEFT, CENTER);
}

void drawButtons() {
  float gap = 7 * ui;
  float totalW = width - 2 * margin;
  float bw = (totalW - gap) / 2.0;

  drawButton(
    margin,
    buttonY,
    bw,
    buttonH,
    "GENERATE",
    ACCENT,
    BG
  );

  drawButton(
    margin + bw + gap,
    buttonY,
    bw,
    buttonH,
    "MORE RANDOM",
    SELECTED,
    FG
  );

  float secondY = buttonY + buttonH + 8 * ui;

  drawButton(
    margin,
    secondY,
    bw,
    buttonH,
    "COPY RESULT",
    CARD,
    FG
  );

  drawButton(
    margin + bw + gap,
    secondY,
    bw,
    buttonH,
    "RESET",
    CARD,
    FG
  );
}

// ============================================================
// RESULT PANEL
// ============================================================

void drawResult() {
  noStroke();
  fill(PANEL);

  rect(
    margin,
    resultY,
    width - 2 * margin,
    resultH,
    10 * ui
  );

  float left = margin + 12 * ui;
  float right = width - margin - 12 * ui;

  fill(ACCENT);
  textAlign(LEFT, CENTER);
  textSize(12 * ui);

  text(
    "PARTITION OF " + target,
    left,
    resultY + 21 * ui
  );

  fill(FG);
  textSize(12 * ui);

  text(
    "Required parts: " + termCount,
    left,
    resultY + 45 * ui
  );

  fill(MUTED);
  textSize(10 * ui);

  text(
    "Actual parts: " + actualLength,
    left,
    resultY + 66 * ui
  );

  float equationY = resultY + 85 * ui;
  float equationH = max(
    50 * ui,
    min(190 * ui, resultH - 145 * ui)
  );

  fill(SELECTED);

  rect(
    left - 3 * ui,
    equationY,
    right - left + 6 * ui,
    equationH,
    8 * ui
  );

  fill(FG);
  textAlign(CENTER, CENTER);

  float fontSize = 15 * ui;
  textSize(fontSize);

  // Try progressively smaller font sizes so the
  // complete expression fits on one line if possible.
  while (
    fontSize > 6 * ui &&
    textWidth(expression) > right - left - 12 * ui
  ) {
    fontSize -= 0.5 * ui;
    textSize(fontSize);
  }

  // If the full expression is still too long,
  // display a preview. Copy preserves all terms.
  String visibleExpression = expression;

  if (
    textWidth(visibleExpression) >
    right - left - 12 * ui
  ) {
    visibleExpression = fitText(
      expression,
      right - left - 12 * ui,
      fontSize
    );
  }

  text(
    visibleExpression,
    width / 2,
    equationY + equationH / 2
  );

  fill(ACCENT);
  textSize(16 * ui);

  text(
    "SUM = " + actualSum,
    width / 2,
    equationY + equationH + 27 * ui
  );

  fill(MUTED);
  textAlign(LEFT, CENTER);
  textSize(9 * ui);

  text(
    "All terms are positive integers.",
    left,
    resultY + resultH - 17 * ui
  );

  textAlign(LEFT, CENTER);
}

// ============================================================
// TEXT FITTING
// ============================================================

String fitText(
  String value,
  float maxWidth,
  float size
) {
  textSize(size);

  if (value == null || maxWidth <= 0) {
    return "";
  }

  if (textWidth(value) <= maxWidth) {
    return value;
  }

  String s = value;

  while (
    s.length() > 0 &&
    textWidth(s + "...") > maxWidth
  ) {
    s = s.substring(0, s.length() - 1);
  }

  return s + "...";
}

// ============================================================
// COPY COMPLETE PARTITION
// ============================================================

void copyResult() {
  try {
    Context context = getActivity();

    if (context == null) {
      statusText = "Clipboard unavailable.";
      return;
    }

    ClipboardManager cb =
      (ClipboardManager) context.getSystemService(
        Context.CLIPBOARD_SERVICE
      );

    if (cb == null) {
      statusText = "Clipboard unavailable.";
      return;
    }

    String result =
      "Integer Partition Explorer\n" +
      "Target = " + target + "\n" +
      "Required parts = " + termCount + "\n" +
      "Actual parts = " + actualLength + "\n" +
      expression + " = " + actualSum;

    cb.setPrimaryClip(
      ClipData.newPlainText(
        "Integer Partition",
        result
      )
    );

    statusText = "Complete partition copied.";

  } catch (Exception e) {
    statusText =
      "Copy failed: " + e.getClass().getSimpleName();
  }
}

// ============================================================
// RESET
// ============================================================

void resetApp() {
  target = 200;
  termCount = 5;

  generateRandomPartition();

  statusText = "Reset to target 200, with 5 parts.";
}

// ============================================================
// SLIDER TOUCH HELPERS
// ============================================================

boolean nearSlider(
  float x,
  float y,
  float trackY
) {
  return
    x >= trackLeft - 15 * ui &&
    x <= trackRight + 15 * ui &&
    abs(y - trackY) <= 18 * ui;
}

// ============================================================
// TOUCH EVENTS
// ============================================================

void mousePressed() {
  calculateLayout();

  if (
    nearSlider(mouseX, mouseY, targetTrackY)
  ) {
    draggingTarget = true;

    updateTarget(
      xToTarget(mouseX)
    );

    return;
  }

  if (
    nearSlider(mouseX, mouseY, termsTrackY)
  ) {
    draggingTerms = true;

    termCount = xToTerms(mouseX);

    return;
  }
}

void mouseDragged() {
  calculateLayout();

  if (draggingTarget) {
    updateTarget(
      xToTarget(mouseX)
    );
  }

  if (draggingTerms) {
    termCount = xToTerms(mouseX);
  }
}

void mouseReleased() {
  calculateLayout();

  if (draggingTarget || draggingTerms) {
    if (draggingTarget) {
      updateTarget(
        xToTarget(mouseX)
      );
    }

    if (draggingTerms) {
      termCount = xToTerms(mouseX);
    }

    draggingTarget = false;
    draggingTerms = false;

    generateRandomPartition();

    return;
  }

  float gap = 7 * ui;
  float totalW = width - 2 * margin;
  float bw = (totalW - gap) / 2.0;

  float secondY = buttonY + buttonH + 8 * ui;

  // First button row.
  if (
    mouseY >= buttonY &&
    mouseY <= buttonY + buttonH
  ) {
    if (
      mouseX >= margin &&
      mouseX <= margin + bw
    ) {
      generateRandomPartition();

    } else if (
      mouseX >= margin + bw + gap &&
      mouseX <= margin + 2 * bw + gap
    ) {
      generateRandomPartition();
    }

    return;
  }

  // Second button row.
  if (
    mouseY >= secondY &&
    mouseY <= secondY + buttonH
  ) {
    if (
      mouseX >= margin &&
      mouseX <= margin + bw
    ) {
      copyResult();

    } else if (
      mouseX >= margin + bw + gap &&
      mouseX <= margin + 2 * bw + gap
    ) {
      resetApp();
    }
  }
}

// ============================================================
// FOOTER
// ============================================================

void drawFooter() {
  fill(MUTED);
  textAlign(CENTER, CENTER);
  textSize(8 * ui);

  text(
    fitText(
      statusText,
      width - 2 * margin,
      8 * ui
    ),
    width / 2,
    footerY
  );

  textAlign(LEFT, CENTER);
}
