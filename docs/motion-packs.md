# AETHER: original pack-inspired locomotion (R6 + R15)

This document describes AETHER's **original procedural interpretations**, not
Roblox's purchased animations. There are **no animation asset IDs**, keyframes
or copyrighted animations copied from the original packs.

## Inspiration and visual direction

| AETHER style | Movement direction |
| --- | --- |
| Toy | Stiff toy-like marching and small geometric steps |
| Robot | Segmented, deliberately mechanical rhythm |
| Ninja | Forward-leaning silent runs, trailing arms |
| Bubbly | Upbeat bouncing gait and side-to-side motion |
| Stylish | Graceful asymmetrical sways and subtle torso turns |
| Mage | Suspended spellcaster-style drift |
| Levitation | Slow floating, outstretched arms, soft foot motion |
| Oldschool | Classic straightforward block-limb swing |
| Vampire | Theatrical posture and calm, slightly hunched stride |
| Astronaut | Low-gravity, slow soft motions |
| Zombie | Slow uneven shuffle and leaning posture |
| Cartoony | Exaggerated rhythmic bouncing and arms |

## Behavior

- The **Character → Custom walking animation** setting must be turned **ON**.
- In Character, choose a style with the dedicated chip gallery or **Walking style**.
- **Walking intensity %** blends the animation into Roblox's existing Animator
  track; reducing it should keep compatibility with many custom experiences.
- Styles use `MotionPacks.luau` profile data and
  `WalkMotion.luau` additive `Motor6D.Transform` animation.
- R6 is animated through RootJoint, hips, shoulders and neck.
  R15 also uses elbows, knees, ankles and waist where available.
- Movement responds to standing idle, walk/run, jump, freefall, climbing and
  swimming without replacing Roblox AnimationIds or custom Animator tracks.
- No physics changes, flight ability or server-side movement overrides.
- Studio preview mannequins are decorative anchored geometry; check actual
  body motion with an R6 and R15 player character.
- If your experience supplies very different default animations,
  reduce the intensity or disable the overlay.

The official Roblox Creator Hub documents animation packs as seven related
locomotion states (walk, run, idle, jump, fall, swim and climb):
https://create.roblox.com/docs/avatar/animation-packs

## Build

```sh
python tools/build.py
python tools/build.py --check
```

The GitHub Actions workflow automatically updates
`dist/AETHER.client.luau` when modules change. Roblox Studio runtime tests
are still required to verify pose directions across different avatar rigs.


## Community-created UGC-inspired collection (2026)

As of November 2026, Roblox permits eligible Marketplace creators to release
avatar animation packs. The catalog is dynamic: **these 26 styles are a researched
selection, not a census of every available animation**. All animations below
are implemented as new AETHER motion profiles and additive transforms. They do
not read, clone, republish, or re-upload original UGC animation clips.

| New AETHER style | Visual interpretation / inspiration |
| --- | --- |
| Angel Glide | Open shoulders, sustained soft hovering, downstroke landing |
| Bat Swoop | Swooping, wing-like arms, angled midair posture |
| Mermaid Drift | Paired tail-like leg wave, slow lateral body drift |
| Serpent Slither | Serpentine torso twist with wavelike shoulders |
| Cartwheel Flow | Rhythmic lateral tilt and gymnast-like balance |
| Rubberhose | Overshooting rubber-limbed cartoon arm swing |
| Dream Sleep | Curled sleeping drift with tucked arms and knees |
| Plushie | Soft rounded puppet stance, little footsteps |
| Cat Paws | Paws-like curled hands and springy light walking |
| Shy Kawaii | Inward folded arms, small reserved footsteps |
| Gymnast | Spread arms and balanced side-to-side motion |
| Skip Hop | Skipping cadence with alternating little hops |
| Reindeer Prance | Light prancing with high knee accents |
| Fighter | Athletic stance and precise rapid stepwork |
| Harpy Glide | Large open bird-wing arm arc and suspended legs |
| Godly Aura | Ceremonial, slow circular hover |
| Wavy Expressive | Asymmetric arm and torso waves |
| Retro Zombie | Slow offset shuffle and weighted shoulders |
| Tsundere | Expressive reserved gestures and weight shifts |
| Doll Walk | Semi-stiff doll-style delicate stepping |
| Skater | Alternating lateral push and glide |
| Little Duck | Small waddling gait and tiny flaps |
| Floating Head | Head-focused drifting gestures and relaxed limbs |
| Dark Aura | Dark cloak-like hovering posture |
| Anime Hero | Stylized forward lean and expressive step cadence |
| Headless Float | Slow ghostly drifting and oscillating shoulders |

### Research references

The names and broad categories are informed by contemporary Roblox creator
Marketplace listings and community publications. These sources **do not expose
the underlying animation keyframes**, so the AETHER movements are original
interpretations rather than claims of frame-exact reproduction:

- Roblox official publishing guidance:
  https://create.roblox.com/docs/avatar/animation-packs
- Public announcement, full release of UGC animation pack publishing:
  https://devforum.roblox.com/t/full-release-create-and-sell-animation-packs-on-marketplace/4861803
- Floating bat UGC description:
  https://www.rolimons.com/item/98159713314075
- Cartwheel and Flying Head:
  https://www.rolimons.com/ugc-group-store/595372276
- Mermaid, Reindeer:
  https://www.rolimons.com/ugc-group-store/1097526673
- Snake:
  https://www.rolimons.com/ugc-group-store/33201801
- Cuphead Style:
  https://www.rolimons.com/ugc-group-store/34874988
- Sleeping float:
  https://www.rolimons.com/ugc-group-store/34619425
- Plushie:
  https://www.rolimons.com/ugc-group-store/1064471971
- Gymnastics and fighter:
  https://www.rolimons.com/ugc-group-store/251280645
- Cute Wavy Expressive:
  https://www.rolimons.com/ugc-group-store/509059284
- Kawaii and tsundere:
  https://www.rolimons.com/ugc-group-store/17237812
  https://www.rolimons.com/ugc-group-store/916571784
- Community duck-inspired creators:
  https://www.reddit.com/r/RobloxAvatars/comments/1w079fu/
- Catalog Avatar Creator discussions of UGC packs:
  https://www.reddit.com/r/roblox/comments/1upp3l6/

For R15, original creator-pack movement can be far more elaborate than this
local additive overlay. For R6, available joints are fewer: elbows, knees,
ankles and waist fall back to supported shoulders, hips, neck and root.
Aether does **not** provide physical flight or override collision physics.
