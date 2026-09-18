import { PositionType } from "../common/constants/CommonConstants"

export class PostionItem{
  icon : Resource = $r("app.media.ic_train_station")
  text : Resource = $r("app.string.train_station")

  type : PositionType = PositionType.TRAIN_STATION
  lngLat : Array<GeoCoordinates>=[]
}

export class PixelcoordinateS{
  coordinatesX : number =0;
  coordinatesY : number =0;
}

export class GeoCoordinates{
  latitude : number = 0;
  longitude : number = 0;
}