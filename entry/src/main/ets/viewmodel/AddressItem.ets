@Observed
export class Location {
  positionX: number;
  positionY: number;
  originalPositionX: number;
  originalPositionY: number;

  constructor(positionX: number, positionY: number) {
    this.positionX = positionX;
    this.positionY = positionY;
    this.originalPositionX = positionX;
    this.originalPositionY = positionY;
  }
}

export class AddressItem {
  name?: Resource;
  icon?: Resource;
  location: Array<Location> = [];
  textColor?: Resource;
}
