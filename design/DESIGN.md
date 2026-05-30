---
name: Lume Wellness
colors:
  surface: '#f9f9ff'
  surface-dim: '#d6dae4'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f0f3fe'
  surface-container: '#eaeef8'
  surface-container-high: '#e5e8f2'
  surface-container-highest: '#dfe2ed'
  on-surface: '#171c23'
  on-surface-variant: '#43474f'
  inverse-surface: '#2c3138'
  inverse-on-surface: '#edf0fb'
  outline: '#737780'
  outline-variant: '#c3c6d1'
  surface-tint: '#485f84'
  primary: '#001e40'
  on-primary: '#ffffff'
  primary-container: '#1a3456'
  on-primary-container: '#859dc5'
  inverse-primary: '#afc8f2'
  secondary: '#705d00'
  on-secondary: '#ffffff'
  secondary-container: '#fcd401'
  on-secondary-container: '#6f5c00'
  tertiary: '#1e1e20'
  on-tertiary: '#ffffff'
  tertiary-container: '#333335'
  on-tertiary-container: '#9d9b9d'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d5e3ff'
  primary-fixed-dim: '#afc8f2'
  on-primary-fixed: '#001b3b'
  on-primary-fixed-variant: '#2f476b'
  secondary-fixed: '#ffe16e'
  secondary-fixed-dim: '#e9c400'
  on-secondary-fixed: '#221b00'
  on-secondary-fixed-variant: '#544600'
  tertiary-fixed: '#e4e2e4'
  tertiary-fixed-dim: '#c8c6c8'
  on-tertiary-fixed: '#1b1b1d'
  on-tertiary-fixed-variant: '#474649'
  background: '#f9f9ff'
  on-background: '#171c23'
  surface-variant: '#dfe2ed'
  surface-bg: '#fcf8fb'
  surface-card: rgba(255, 255, 255, 0.7)
  timeline-gradient-start: '#001e40'
  timeline-gradient-end: '#fcd400'
  glow-yellow: rgba(252, 212, 0, 0.2)
  fat-burn-accent: '#e9c400'
typography:
  display-timer:
    fontFamily: Hanken Grotesk
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Hanken Grotesk
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 34px
  headline-lg-mobile:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 30px
  headline-md:
    fontFamily: Hanken Grotesk
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 17px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 20px
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 32px
  gutter-card: 16px
  margin-page: 20px
---

## Brand & Style
Lume is a high-end wellness and fasting companion designed to evoke a sense of calm, clarity, and metabolic health. The brand personality is professional yet nurturing, targeting health-conscious individuals who appreciate clean, data-driven interfaces.

The design style is **Modern Corporate with Glassmorphic accents**. It utilizes a sophisticated "light mode" foundation characterized by high-key lighting, soft-focus imagery, and airy whitespace. Depth is created through translucent, blurred layers (glassmorphism) that suggest a "clean" and "breathable" atmosphere, reflecting the physiological state of fasting. Subdued animations (pulse and glow effects) provide a sense of "life" and active monitoring without being distracting.

## Colors
The palette is rooted in a deep "Midnight Navy" primary color that provides authority and readability. This is contrasted by a "Radiant Gold" secondary color, which symbolizes energy, metabolic activity, and success.

- **Primary (#001e40):** Used for headlines, primary buttons, and core branding.
- **Secondary (#fcd400):** Reserved for "active" states, progress indicators, and significant status highlights.
- **Background (#fcf8fb):** A soft, slightly warm-tinted white that reduces eye strain compared to pure white.
- **Glass Effects:** Use white at 70% opacity with a 12px backdrop blur for container backgrounds to maintain the airy aesthetic.

## Typography
The system uses **Hanken Grotesk** for display and headline roles to provide a clean, modern, and slightly high-fashion feel. **Inter** is used for body text and labels to ensure maximum legibility and a systematic, functional feel.

Key typographic rules:
- **Tabular Numerals:** Use for timers and progress counters to prevent layout shift.
- **Caps for Labels:** Small labels and status indicators should always use the `label-caps` style for clear categorization.
- **Hierarchy:** Primary Navy is the default text color; use On-Surface-Variant (Grey) for secondary information like "yesterday" or "today" timestamps.

## Layout & Spacing
The layout follows a **Fixed-Width / Centered** model optimized for mobile devices (max-width: 448px), centered on larger viewports.

- **Vertical Rhythm:** A stack-based spacing system (8px, 16px, 32px) ensures consistent vertical flow.
- **Margins:** A standard 20px page margin creates a safe breathable zone for content.
- **Bento Grid:** Information cards (streak, hydration) use a 2-column grid with 16px gutters to efficiently organize dense data.
- **Vertical Timeline:** The central feature uses a centered vertical line with nodes offset by 32px of horizontal gap, creating a clear chronological narrative.

## Elevation & Depth
Depth is expressed through transparency and soft light rather than traditional heavy shadows.

- **Glass Cards:** Primary containers use 70% white backgrounds with 12px blur. These should have a very subtle 1px border (#eae7ea at 50% opacity) to define the edge.
- **Layering:** Use `shadow-sm` for standard cards and `shadow-lg` for primary floating action buttons to denote interactability.
- **Active Glow:** Interactive or "active" states (like the current status chip) utilize an ambient yellow glow (`0 0 20px rgba(252, 212, 0, 0.2)`) to draw the eye without increasing perceived weight.

## Shapes
The shape language is rounded and friendly, reinforcing the wellness aspect. 

- **Containers/Cards:** Use 1.5rem (24px) for cards to create a soft, inviting container.
- **Interactive Elements:** Buttons use 0.75rem (12px) for a balanced, modern feel.
- **Status Indicators:** Use full rounded (Pill) shapes for chips and navigation active states.
- **Nodes:** Timeline nodes use concentric circles (border-4) to emphasize focal points.

## Components

### Buttons
- **Primary:** Full width, Navy background, white text, 1.5rem padding, shadow-lg. Scale to 98% on active tap.
- **Secondary/Text:** Primary Navy text, centered, with icon support. Subtle hover state with a light grey background.

### Cards (Glass)
- 70% white background, 12px backdrop-blur, 1px border.
- Internal spacing is typically 16px (p-4).

### Status Chips
- Pill-shaped, light opacity background (e.g., Primary 5%), with a pulsing dot indicator (2x2 units).

### Navigation
- Bottom navigation utilizes a fixed 80px height bar. Active states are indicated by a high-contrast pill-shaped background (Secondary Gold or Primary Navy depending on the theme).

### Timeline
- A vertical linear gradient line (Navy to Gold) with 16px diameter nodes. Nodes for "past" events are solid; "current" nodes use a pulsing indicator.