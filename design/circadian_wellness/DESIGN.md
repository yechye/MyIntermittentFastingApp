---
name: Lume Fasting
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
  on-surface-variant: '#44474e'
  inverse-surface: '#2c3138'
  inverse-on-surface: '#edf0fb'
  outline: '#74777f'
  outline-variant: '#c4c6cf'
  surface-tint: '#485f84'
  primary: '#000511'
  on-primary: '#ffffff'
  primary-container: '#001e40'
  on-primary-container: '#6f87ae'
  inverse-primary: '#afc8f2'
  secondary: '#3c692b'
  on-secondary: '#ffffff'
  secondary-container: '#baeea0'
  on-secondary-container: '#406d2f'
  tertiary: '#040403'
  on-tertiary: '#ffffff'
  tertiary-container: '#1e1e1b'
  on-tertiary-container: '#878681'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d5e3ff'
  primary-fixed-dim: '#afc8f2'
  on-primary-fixed: '#001b3b'
  on-primary-fixed-variant: '#2f476b'
  secondary-fixed: '#bdf1a3'
  secondary-fixed-dim: '#a1d489'
  on-secondary-fixed: '#052100'
  on-secondary-fixed-variant: '#255015'
  tertiary-fixed: '#e5e2dd'
  tertiary-fixed-dim: '#c9c6c1'
  on-tertiary-fixed: '#1c1c19'
  on-tertiary-fixed-variant: '#474743'
  background: '#f9f9ff'
  on-background: '#171c23'
  surface-variant: '#dfe2ed'
  brand-sage: '#7FB069'
  surface-main: '#fcf8fb'
  glass-border: rgba(234, 231, 224, 0.5)
  timeline-start: '#001e40'
  timeline-end: '#7FB069'
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
  gutter-card: 16px
  margin-page: 20px
  stack-lg: 32px
---

## Brand & Style

Lume Fasting is a health and wellness platform that balances clinical precision with a nurturing, organic feel. The brand personality is **Modern-Organic**: it uses the structural reliability of a dark navy "Corporate" palette but softens it with "Sage Green" accents and glassmorphic elements to evoke growth, vitality, and calm.

The design style is a hybrid of **Glassmorphism** and **Minimalism**. It utilizes translucent layers and backdrop blurs to create a sense of lightness and breathability, mirroring the physical feeling of fasting. The emotional response should be one of disciplined progress—achieved through clean typography and data-driven layouts—tempered by gentle, pulsing animations that feel "alive."

## Colors

The palette is anchored by **Deep Midnight (#001e40)**, providing a high-contrast, authoritative base for typography and primary actions. The core accent is **Brand Sage (#7FB069)**, a muted green used to signify active states, health "wins," and progress.

The background is not a pure white but a warm, desaturated pink-white (**#fcf8fb**) which reduces eye strain and reinforces the organic brand feel. Secondary elements use varying opacities of the brand sage (e.g., 10% fills for status badges) to create a layered hierarchy without introducing new hues. A vertical gradient transition from Midnight to Sage is used as a metaphorical "metabolic switch" indicator in the timeline.

## Typography

The system uses **Hanken Grotesk** for all display and headline roles. Its sharp, contemporary geometry provides a "tech-forward" look. Large timer displays should use tabular figures to prevent horizontal jitter during countdowns.

**Inter** is utilized for body text and functional labels. Labels should frequently employ an all-caps style with increased letter spacing (+0.05em) to differentiate metadata from primary content. The hierarchy relies on weight contrast—using 600-700 weight for key data points and 400 weight for supporting descriptions.

## Layout & Spacing

The layout follows a **Fluid Grid** approach for mobile, constrained to a maximum content width of 448px (max-w-md) for larger screens to maintain readability. The spacing system is built on a 4px base unit.

Key structural spacing includes:
- **Page Margins:** 20px on left/right for mobile screens.
- **Vertical Rhythm:** A standard 32px (stack-lg) gap between major sections, and 16px (stack-md) for related grouping.
- **Bento Grid:** Information cards use a 2-column grid with a 16px gutter.
- **Safe Area:** A bottom padding of at least 96px is required to account for the fixed navigation bar and system gestures.

## Elevation & Depth

Hierarchy is established through **Glassmorphism** and **Ambient Shadows** rather than stark color changes.

- **Surface 0:** The main page background (#fcf8fb).
- **Surface 1 (Glass):** Semi-transparent white (70% opacity) with a 12px backdrop blur. These containers use a subtle 1px border (#EAE7E0 at 50% opacity) to define edges without adding visual weight.
- **Active Elevation:** Elements signifying "live" status (like the timer or active fast button) utilize a **Glow-active shadow**: a soft, 20px blur of the brand sage color at 20% opacity.
- **Interactive Depth:** Physicality is reinforced through subtle scale-down transitions (scale-98) upon interaction.

## Shapes

The shape language is primarily **Rounded (8px-24px)**, moving away from sharp industrial edges to a softer, "humanist" feel.

- **Standard Containers:** Cards and major sections use `rounded-xl` (1.5rem / 24px) to create a friendly, approachable container.
- **Buttons & Inputs:** Use `rounded-xl` for large actions and `rounded-lg` (1rem / 16px) for secondary utility buttons.
- **Status Indicators:** Use `rounded-full` (Pill) for badges and the timeline node indicators to emphasize a continuous, non-linear flow.

## Components

### Buttons
- **Primary:** Full-width, Brand Sage background, white text, 1.5rem rounding. Should include a subtle drop shadow.
- **Ghost/Text:** Brand Sage text with no background, used for secondary modifications like "Edit."

### Cards (Glassmorphic)
- Containers for stats (Bento style). Must include `backdrop-filter: blur(12px)` and a light 1px border. Inside, labels are stacked above primary metrics.

### Timeline
- A central 2px vertical line with a gradient transition. 
- **Nodes:** Large nodes (24px) for active progress with a "pulse" animation; smaller nodes (16px) for past/future milestones.

### Navigation Bar
- Fixed at the bottom, using the surface background with a 1px top border.
- **Active State:** A filled pill background using the Brand Sage color for the selected icon, with other icons remaining as outlines in the neutral variant.

### Status Badges
- Small, pill-shaped indicators with 10% opacity backgrounds of the status color (e.g., Sage for Active, Red for Alert). Include a leading dot (4px) with a pulse animation for "Live" states.