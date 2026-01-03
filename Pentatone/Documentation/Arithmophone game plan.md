ARITHMOPHONE APP ECOSYSTEM - GAME PLAN

The Arithmophone project has been going for a few years. It is a one-person project, created and maintained by musician and amateur software developer Chiel Zwinkels.

Over the pas 4 years, a number of web apps have been made under the 'Arithmophone' umbrella, both with built in sound engines and as MIDI controllers for external (software/hardware) instruments. At this point, work is under way for the next generation (gen 5) of Airthmophone apps, which will now be native iOS apps for the first time. There are plans for releasing 5 separate apps. All of these apps will have their own unique keyboard design, but they will all be sharing the same sound engine.

1) PENTATONE - featuring a pentatonic music keyboard (current app, in development but nearing completion of version 1)

2) DIATONE - a diatonic version of the pentatone, using diatonic scales instead of pentatonic scales, with a slightly larger keyboard but otherwise mostly identical (currently just a design mockup, could possibly be cloned from pentatone repo and adjusted accordingly)

3) TONEHIVE - a 29 note per octave keyboard in 7-limit just intonation. Has a completely different UI from the pentatone/diatone apps (currently in development, keyboard UI is working well, sound engine is very basic at the moment, to be replaced by the full sound engine that's currently being implemented in the Pentatone app)

4) IVORY - a 'traditional' 12 note per octave piano-style keyboard in standard tuning (12 tone equal temperament). Has a different keyboard from the ToneHive, but will otherwise share its UI (currently just a design mockup, could possibly be cloned from ToneHive repo and adjusted accordingly)

5) HUYGENS - a 31 note per octave keyboard for 31 tone equal temperament. Has a different keyboard from the ToneHive, but will otherwise share its UI (currently just a design mockup, could possibly be cloned from ToneHive repo and adjusted accordingly)


These apps will have different features and target audiences:


PENTATONE / DIATONE

The Pentatone and Diatone apps are built with a layered structure. On the surface, they are just very easy music keyboards with some selectable scales and preset sound available. But there are two things that add depth: 
1) both apps feature a very comprehensive scale selection system with built in documentation that can teach a lot about music theory and tuning (just intonation vs equal temperament) that can be new/valuable even to advanced musicians.
2) both apps feature a full fledged original synth engine with all sound parameters available in the UI and built in documentation explaining the fundamentals of sound synthesis

Target audiences:
- Musicians wanting a very fun and accessible 'music toy' - something that isn't a 'pro' instrument but can be engaging and enjoyable to musicians in the same way that for example a Yamaha PortaSound Keyboard, a Casio SK-1 sampler or a Korg Volca synth can be.
- Kids looking for a first instrument to start making music with, like a 21st century version of a recorder or a toy piano only much easier to play (especially Pentatone)
- Music educators and beginner level students interested in learning the basic of music scale theory
- More advanced musicians/serious students looking to get a firmer grip on music scale theory and practice (especially Diatone)



TONEHIVE

The ToneHive is for the truly curious, wanting to take a deep dive into 7-limit just intonation tuning. It features a completely novel keyboard design that is fully optimized for its specific selection of notes.

Target audience:
- advanced musicians with an interest in microtonality, particularly just intonation 



IVORY

The Ivory app will be the least original of the Arithmophone app and will be most similar to other synthesizer apps. It will just have a regular piano keyboard in standard tuning, but it still features the full Arithmophone sound engine, with a well thought out parameter editing system and some unique twists (2x2 operator binaural FM, comprehensive touch/aftertouch response). This will make the app 'easy to get' for people who have already used other synth apps, and geared toward sound design more than music theory explorations.

Target audience:
- Synth enthusiasts



HUYGENS

The Huygens is for those that want to explore 31 tone equal temperament. It features a layout that is related to the Huygens-Fokker organ, but highly tweaked and optimised for touch screen use.

Target audience:
- advanced musicians with an interest in microtonality, particularly 31 EDO 




LAUNCH ORDER CONSIDERATIONS

The Pentatone app will be finished first, but should it also be released first? It will probably not be too much work to finish the ToneHive app once the Pentatone app is completed and the engine / preset structure can be ported. The Pentatone design is very new and aimed at a very broad audience, which is new for the Arithmophone project. PRevious web app releases have been mostly targeted at microtonal music and synth enthusiasts, and have already had some modest success in those circles (featured on major synth blogs, some 1000s of youtube view for demonstration videos, nothing major but at least some bit of resonance within the small subculture. It might be smart to first release iOS an app that is immediately recognisable to those who have encountered earlier incarnations of the Arithmophone, to gain a bit of a foothold with the 'innnovator/early adapter' crowd before releasing a more widely targeted iOS app?

Launch apps 1 by 1 or in groups? Pentatone and Diatone form a natural group, as would ToneHive, Ivory and Huygens. What are the pros and cons of doing 5 separate staged releases vs 2 more comprehensive multi-app releases?

Make everything iPhone+iPad or limit some apps to iPad only? Pentatone is definitely the most suitable for use on phone-sized screens, followed by Diatone and Ivory. ToneHive and Huygens are strongly optimized for iPad in landscape mode (fullscreen), but is there anything against also releasing them for iPhone? 


MONETIZATION CONSIDERATIONS

Note: monetization is not our primary concern for this project, it is a passion project first and foremost. All apps hould definitely remain ad-free at all times.

Make all apps free or make some apps free and others paid upfront? Pentatone and Diatone should definitely be free apps, considering their educational potential. ToneHive and Huygens should probably be free in their basic version at least. Ivory could be free or paid for, whichever will be most beneficial to the project.

In app purchases: the layered structure of Pentatone and Diatone makes it so that full access to the sound editing/preset saving functionality could be a natural in app purchase. But for the other three apps, this sound editing will be a more integral part of their UI so it would not make too much sense to offer them in a version without this functionality (or would it? could be worked around perhaps). Would it be weird/offputting if features that are available for free in some Arithmophone apps would have to be paid for in others? 

Other options for in app purchases could be midi support and/or AUv3 support (both yet to be implemented). Comprehensive midi support would require MPE and/or .tun/.scala support for microtonality, charging for this would seem very fair. 

Where could the most gain be had from monetization? The Pentatone/Diatone apps target a very large audience, but how many of them would be interested in paying for features like midi support or detailed sound editing. The ToneHive and Huygens apps are tailored more toward specialists who would be more likely to pay for such features, but their numbers will not be that large. The Ivory app may strike the best balance between mass appeal and a space where people are used to paying for 'pro' features or even upfront for the app itself, but focusing on the one app for monetization may appear disingenuous.

It is interesting to consider the strategy that optimizes for revenue, but what is the strategy that optimizes for total reach (number of downloads, number of active users), which is at least as important for our considerations. Would that be to make everything completely free? Or could the possible perceived 'valuelessness' of that strategy actually hinder the total reach?
