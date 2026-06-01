---
name: Vitality Wellness System
colors:
  surface: '#faf9fe'
  surface-dim: '#dad9df'
  surface-bright: '#faf9fe'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f4f3f8'
  surface-container: '#eeedf3'
  surface-container-high: '#e9e7ed'
  surface-container-highest: '#e3e2e7'
  on-surface: '#1a1b1f'
  on-surface-variant: '#42493d'
  inverse-surface: '#2f3034'
  inverse-on-surface: '#f1f0f5'
  outline: '#72796c'
  outline-variant: '#c2c9ba'
  surface-tint: '#3c692b'
  primary: '#3c692b'
  on-primary: '#ffffff'
  primary-container: '#7fb069'
  on-primary-container: '#174207'
  inverse-primary: '#a1d489'
  secondary: '#515f75'
  on-secondary: '#ffffff'
  secondary-container: '#d5e3fe'
  on-secondary-container: '#57657c'
  tertiary: '#596057'
  on-tertiary: '#ffffff'
  tertiary-container: '#9da59a'
  on-tertiary-container: '#333b33'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#bdf1a3'
  primary-fixed-dim: '#a1d489'
  on-primary-fixed: '#052100'
  on-primary-fixed-variant: '#255015'
  secondary-fixed: '#d5e3fe'
  secondary-fixed-dim: '#b9c7e1'
  on-secondary-fixed: '#0d1c2f'
  on-secondary-fixed-variant: '#3a475d'
  tertiary-fixed: '#dde5d9'
  tertiary-fixed-dim: '#c1c9bd'
  on-tertiary-fixed: '#161d16'
  on-tertiary-fixed-variant: '#414940'
  background: '#faf9fe'
  on-background: '#1a1b1f'
  surface-variant: '#e3e2e7'
typography:
  display:
    fontFamily: Hanken Grotesk
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Hanken Grotesk
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Hanken Grotesk
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 34px
  headline-md:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Hanken Grotesk
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Hanken Grotesk
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Hanken Grotesk
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Hanken Grotesk
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  container-padding: 20px
  stack-gap: 12px
  section-gap: 32px
  gutter: 16px
---

## Brand & Style

The design system is rooted in a **Premium iOS aesthetic**, prioritizing clarity, utility, and a sense of calm essential for a wellness and fasting application. It draws heavily from **Minimalism** and **Modern Corporate** influences to create a high-trust environment that feels both native to the device and distinct in its editorial polish.

The emotional response should be one of "effortless discipline"—providing the user with precise data and controls without causing cognitive fatigue. Visuals are characterized by generous whitespace, a soft organic palette, and a rigorous adherence to a structured grid that echoes the precision of a clock.

## Colors

The palette is centered around **Vitality Sage (#7FB069)**, a color chosen to represent health, growth, and natural rhythms. This is paired with an **off-white background** to reduce glare and provide a softer, more premium feel than pure white.

- **Primary:** Vitality Sage is used for primary actions, progress indicators, and active states.
- **Secondary:** A deep navy-charcoal is used for primary headings to ensure high legibility and a grounded feel.
- **Surface:** Components sit on pure white (#FFFFFF) cards or grouped sections to create a subtle lift from the off-white background.
- **Functional:** Success, warning, and error states should use desaturated versions of their respective hues to maintain the calm aesthetic.

## Typography

This design system exclusively uses **Hanken Grotesk**. Its contemporary, clean letterforms provide the "utility" feel requested while remaining approachable.

- **Scale:** Use the `display` style for active timers or large numeric data.
- **Hierarchy:** Maintain a clear distinction between headers and body text using weight (600 for headers, 400 for body).
- **Labels:** Small labels use a slightly heavier weight (500-600) and increased letter spacing to ensure legibility at small sizes, particularly for metadata and secondary stats.

## Layout & Spacing

The system utilizes a **fixed-fluid hybrid grid**. On mobile, it follows a strict 4-column layout with 20px side margins. On larger screens, content is constrained to a maximum width of 600px for utility views (like settings or timers) to maintain the iOS "handheld" focus.

- **Grouped Logic:** Elements are organized into logical "stacks." A gap of 12px is used between items within a group, while a larger 32px gap separates distinct functional sections.
- **Safe Areas:** Adhere to platform-standard safe areas for top bars and home indicators, ensuring the off-white background bleeds into the status bar area for a seamless look.

## Elevation & Depth

Hierarchy is achieved primarily through **Tonal Layering** rather than heavy shadows.

- **Level 0:** The base off-white background (#F9F9F9).
- **Level 1:** Content cards and grouped list containers in pure white (#FFFFFF). These use a very soft, 10% opacity neutral shadow to provide just enough definition to separate from the background.
- **Level 2:** Floating action buttons or active modals. These use a slightly more pronounced ambient shadow (15% opacity, 20px blur) to indicate interactivity.
- **Dividers:** Use hairline 1px strokes (#E5E5E5) for internal list separations, ensuring they do not touch the outer edges of the container (inset dividers).

## Shapes

The shape language is consistently **Rounded**, mirroring the friendly but professional nature of wellness products. 

- **Containers:** Cards and grouped sections use `rounded-lg` (16px/1rem).
- **Interactive Elements:** Buttons and input fields use `rounded-lg` (16px/1rem).
- **Special Elements:** Segmented controls and small chips use a full pill-shape to distinguish them from primary structural cards.

## Components

### Buttons & Interactivity
- **Primary Button:** Solid fill of Vitality Sage with white text. High-contrast, 16px corner radius.
- **Secondary Button:** Ghost style with a Vitality Sage border and text, or a light sage tint (#E8F0E4) background.

### Grouped Settings
- **Containers:** White cards with rounded corners.
- **Rows:** Each row is 52px high (minimum), featuring an icon (left), label (center), and chevron or control (right).
- **Dividers:** Inset dividers that start after the icon to maintain visual alignment.

### Native-Style Toggles
- Use a classic iOS-style switch. When "on," the track is Vitality Sage. When "off," it is a light neutral gray. The thumb is always pure white with a subtle drop shadow.

### Segmented Controls
- A recessed, rounded track in a light gray (#EFEFEF).
- The active segment is a white "floating" card that slides between options, using a soft shadow to indicate it is the topmost layer.

### Cards
- Used for dashboard stats. These should feature a vertical layout: a small uppercase label in Vitality Sage at the top, followed by a large numeric display, and secondary unit text below.