//
//  Development roadmap.swift
//  Penta-Tone
//
//  Created by Chiel Zwinkels on 14/12/2025.
//

/*

MAIN
 √ Fix iOS 15 compatibility
 √ Add oscillator waveform to parameters
 √ add initial touch and aftertouch sensitivity
 - try different filters
 - implement fine tune and octave adjustments
 - switch over to limited polyphony + voice management (round robin)
 - switch over to stereo architecture
 - implement modulation generators
 - implement modulators in parameter structure
 - create preset management
 >> sanity check code structure
 - create developer view for sound editing/storing presets
 - add macro control
 - add drone note toggles to central note buttons?
 (- port engine to tonehive)
 - add in app documentation
 
UI
 √ ET / JI: display as EQUAL / JUST
 √ Improve spacing/layout
 √ Implement scale type graphics display (raw shapes or image files?)
 √ Implement note name display
 - Implement basic tooltip structure (toggle on/of in voice menu?)
 
MINOR IMPROVEMENTS
 √ Change intonation display from ET/JI to EQUAL / JUST
 √ Check font warning
 - distinguish between iPad landscape and iPad portrait for font sizes? (apparently tricky, couldn't get to work on first try - also, looking quite good already anyway)
 √ check delay dry/wet mix parameter direction, 0.0 is now fully wet and 1.0 is fully dry (?)
 - check: what is the update rate for touch (x position) changes? Filter sweep very choppy, cause?
 
 
 
 PRESETS
 
 1.1  Keys (Wurlitzer-esque sound)
 1.2  Mallets (Marimba-esque sound)
 1.3  Sticks (Glockenspiel-esque sound)
 1.4  Pluck (Harp-esque sound)
 1.5  Pick (Koto-esque sound)
 
 2.1  Bow (Cello-esque sound)
 2.2  Breath (Low whistle-esque sound)
 2.3  Tube (Rock Organ-esque sound)
 2.4  Transistor (Analog polysynth-esque sound)
 2.5  Chip (Square Lead-esque sound)
 
 3.1  Ocean (Analog bass-esque sound)
 3.2  Forest (lively, organic sound)
 3.3  Field (warm, airy sound)
 3.4  Nebula (Warm, ethereal sound)
 3.5  Haze (Granular-esque sound)
 
 
 KEY TRANSPOSITION
 
 Key    ET pitch factor     JI pitch factor
 Ab     -6 semitones        * 
 Eb     +1 semitones        * 256/243
 Bb     -4 semitones        * 64/81
 F      +3 semitones        * 32/27
 C      -2 semitones        * 8/9
 G      +5 semitones        * 4/3
 D       0 semitones        * 1
 A      -5 semitones        * 3/4
 E      +2 semitones        * 9/8
 B      -3 semitones        * 27/32
 F#     +4 semitones        * 81/64
 C#     -1 semitones        * 243/256
 G#     +6 semitones        * 729/512
 
 
 
 */
