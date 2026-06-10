// Trace It Back — the activity's phase enum.
//
// (The Voltix dialogue engine that used to live here was removed when the mascot,
// the speech bubble, all dialogue and all VO were dropped. The controller now owns
// the silent step machine — instruction captions + sequential source walkthrough.)

/// The activity's beats. The gesture turns the MAGNET in [magnet], the TURBINE in
/// [turbine]; in [source] the activity walks through the sources one by one.
enum TBPhase { intro, magnet, turbine, source, closing }
