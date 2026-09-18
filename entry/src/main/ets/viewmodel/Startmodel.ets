interface IStart{
  day:Resource[];
  duck:Resource[];
  night:Resource[];
}
export const startImages : IStart ={
  day:[
    $r("app.media.splash1"),
    $r("app.media.splash2"),
    $r("app.media.splash3")
  ],
  duck:[
    $r("app.media.splash4"),
    $r("app.media.splash5"),
    $r("app.media.splash6")
  ],
  night:[
    $r("app.media.splash7"),
    $r("app.media.splash8"),
    $r("app.media.splash9")
  ]
}