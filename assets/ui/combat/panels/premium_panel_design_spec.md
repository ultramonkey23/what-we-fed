# Premium UI Panel Design Specifications

## Panel Base Design

### Core Structure
```
+----------------------------------------+
| 2px glowing border (energy color)      |
| +------------------------------------+ |
| | 1px dark border (#2A2A2A)          | |
| | +--------------------------------+ | |
| | | Gradient background             | | |
| | | #0F0F0F -> #121212 (vertical)  | | |
| | | Subtle noise texture            | | |
| | +--------------------------------+ | |
| |                                    | |
| | Content area with 8px padding      | |
| |                                    | |
| +------------------------------------+ |
| Bottom 2px accent line (energy glow)   |
+----------------------------------------+
```

### Energy Color Variants
- **Default UI**: Cyan (#00FFFF) glow
- **Warning/Combat**: Red (#CD2626) glow  
- **Mutation**: Purple (#FF00FF) glow
- **Power**: Yellow (#FFFF00) glow

### Panel Types

#### Performance Panel (Top Left)
- **Dimensions**: 156x60px
- **Content**: Performance metrics, combo counter
- **Styling**: Cyan energy glow, compact layout
- **Elements**:
  - Header: "PERFORMANCE" (uppercase, 10px)
  - Progress: Numeric display (14px, bold)
  - Status: Current state (12px)
  - Claims: Reward count (12px)

#### Offer Panel (Center/Right)
- **Dimensions**: 320x80px
- **Content**: Creature bond/eat offers
- **Styling**: Purple energy glow for mutation choices
- **Elements**:
  - Title: Creature name (14px, bold)
  - Description: Bond/Eat choice (12px)
  - Hint: Control prompt (10px, italic)
  - Progress: Decision timer bar

#### Status Panel (Top Right)
- **Dimensions**: 200x60px
- **Content**: Health, support status, run info
- **Styling**: Yellow energy glow for vital info
- **Elements**:
  - Health bar with gradient fill
  - Support creature status
  - Run phase indicator

### Visual Effects

#### Border Glow
- 2px outer border with subtle pulse animation
- Energy color with 0.3 opacity base
- Pulse to 0.6 opacity every 2 seconds

#### Background Gradient
- Vertical gradient from #0F0F0F (top) to #121212 (bottom)
- Subtle noise texture overlay (10% opacity)
- No hard edges - smooth transitions

#### Text Styling
- Primary: #E0E0E0, regular weight
- Headers: #FFFFFF, bold, uppercase
- Highlights: Energy colors with glow effect
- Shadows: 1px #000000 at 50% opacity

### Animation States

#### Idle State
- Subtle border glow pulse
- No background animation
- Text static

#### Active State
- Border glow intensifies (0.8 opacity)
- Background shifts slightly lighter
- Text may glow for emphasis

#### Warning State
- Border becomes red energy glow
- Faster pulse rate (1 second)
- Background tint with red overlay

### Implementation Notes

#### Performance Considerations
- Use shader-based glow effects for efficiency
- Limit animation complexity during combat
- Pre-render gradients where possible

#### Accessibility
- Maintain high contrast for readability
- Color-blind friendly energy color variants
- Clear text hierarchy regardless of effects

#### Scalability
- Design scales proportionally
- Border widths remain consistent
- Text sizes scale with panel size
