import { Map as MapView } from './MapView';

@Entry
@Component
struct Mapcoment {
  build() {
    Column() {
      MapView()
    }
    .width('100%')
    .height('100%')
  }
}
