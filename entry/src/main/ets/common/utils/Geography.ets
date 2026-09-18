import { PixelcoordinateS } from "../../viewmodel/PositonItem"
import { CommonConstants  } from "../constants/CommonConstants"

export class Geography{
  public static toPixelCoordinate(latitude : number,longitude:number):PixelcoordinateS{
    const yMin = Geography.Mercatory(CommonConstants.SOUTH_LATITUDE)
    const yMax = Geography.Mercatory(CommonConstants.NORTH_LATITUDE)
    const xFactor = CommonConstants.MAP_WIDTH/(CommonConstants.EAST_LONGITUDE - CommonConstants.WEST_LONGITUDE)
    const yFactor = CommonConstants.MAP_HEIGHT/(yMax-yMin)

    let x = (longitude - CommonConstants.WEST_LONGITUDE)* xFactor + CommonConstants.X_ADJ;
    let y = (yMax - Geography.Mercatory(latitude)) *yFactor + CommonConstants.Y_ADJ
    return{coordinatesX:x,coordinatesY:y}
  }
  public static Mercatory(latitude:number):number{
    return Math.log(Math.tan((latitude* CommonConstants.RADIAN_CONSTANT/CommonConstants.DOUBLE_OR_HALF)+
      (CommonConstants.QUARTER_CIRCLE)))
  }

}