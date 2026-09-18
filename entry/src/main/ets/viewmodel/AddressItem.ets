@Observed
export class Location {
  positionX: number;
  positionY: number;
  oripositionX: number;
  oripositionY: number;

  constructor(positionX: number, positionY: number) {
    this.positionX = positionX;
    this.positionY = positionY;
    this.oripositionX = positionX;
    this.oripositionY = positionY;
  }
}

export class AddressItem {
  name?: Resource;
  icon?: Resource;
  location: Array<Location> = [];
  textColor?: Resource;
}
