import {
  AMap, CameraPosition, CameraUpdateFactory, LatLng, LatLngBounds, MapView,
  MapViewComponent, MapViewCreateCallback, MapViewManager, Marker, MarkerOptions,
  OnCameraChangeListener
} from '@amap/amap_lbs_map3d';
import { Campus } from '../common/Campus';
import { CAMPUS_BOUNDARY, CampusCoordinate } from '../common/CampusBoundary';
import { campusPlaces, CampusPlace } from '../viewmodel/CampusPlace';

let nextCampusMapId: number = 0;

@Component
export struct Campus3DMapView {
  @Prop @Watch('onSelectedPlaceChanged') selectedPlaceIndex: number = 0;
  initialCamera?: CameraPosition;
  keepSavedTarget: boolean = true;
  onPlaceSelected: (index: number) => void = (_index: number): void => {};
  onCameraChanged: (position: CameraPosition) => void = (_position: CameraPosition): void => {};

  private mapViewName: string = `xpu-campus-3d-${++nextCampusMapId}`;
  private mapView?: MapView;
  private map?: AMap;
  private maskSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private maskContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.maskSettings);
  private maskReady: boolean = false;
  private maskWidth: number = 0;
  private maskHeight: number = 0;

  private onMapViewCreated: MapViewCreateCallback = (view?: MapView, name?: string): void => {
    if (!view || (name !== this.mapViewName && view.getMapViewName() !== this.mapViewName)) {
      return;
    }
    this.mapView = view;
    view.onCreate();
    view.onResume();
    view.getMapAsync((map: AMap): void => {
      if (this.mapView !== view) {
        return;
      }
      this.setupMap(map);
    });
  };

  aboutToAppear(): void {
    MapViewManager.getInstance().registerMapViewCreatedCallback(this.onMapViewCreated);
  }

  aboutToDisappear(): void {
    MapViewManager.getInstance().unregisterMapViewCreatedCallback(this.onMapViewCreated);
    this.mapView?.onPause();
    this.mapView?.onDestroy();
    this.mapView = undefined;
    this.map = undefined;
    this.maskReady = false;
  }

  private setupMap(map: AMap): void {
    this.map = map;
    map.showBuildings(true);
    map.setMinZoomLevel(17.1);
    map.setMaxZoomLevel(20);
    map.setMapStatusLimits(new LatLngBounds(
      new LatLng(34.3600, 109.1824), new LatLng(34.3703, 109.1897)));
    map.getUiSettings()?.setZoomControlsEnabled(false);
    map.getUiSettings()?.setCompassEnabled(true);

    map.setOnCameraChangeListener(new OnCameraChangeListener(
      (position: CameraPosition): void => {
        this.onCameraChanged(position);
        this.drawOutsideMask();
      },
      (position: CameraPosition): void => {
        this.onCameraChanged(position);
        this.drawOutsideMask();
      }));
    map.setOnMapLoadedListener((): void => this.drawOutsideMask());
    map.setOnMarkerClickListener((marker: Marker): boolean => {
      const index = campusPlaces.findIndex((place: CampusPlace): boolean => place.name === marker.getTitle());
      if (index >= 0) {
        this.onPlaceSelected(index);
      }
      return true;
    });

    for (const place of campusPlaces) {
      if (place.latitude === undefined || place.longitude === undefined) {
        continue;
      }
      const markerOptions: MarkerOptions = new MarkerOptions()
        .setPosition(new LatLng(place.latitude, place.longitude))
        .setTitle(place.name)
        .setSnippet(place.description);
      map.addMarker(markerOptions);
    }

    const initialPlace: CampusPlace = campusPlaces[this.selectedPlaceIndex];
    const selectedTarget: LatLng = new LatLng(initialPlace.latitude ?? Campus.LATITUDE,
      initialPlace.longitude ?? Campus.LONGITUDE);
    map.moveCamera(CameraUpdateFactory.newCameraPosition(new CameraPosition(
      this.initialCamera && this.keepSavedTarget ? this.initialCamera.target : selectedTarget,
      this.initialCamera?.zoom ?? 17.9,
      this.initialCamera?.tilt ?? 45,
      this.initialCamera?.bearing ?? 0)));
    this.drawOutsideMask();
  }

  private onSelectedPlaceChanged(): void {
    const place: CampusPlace = campusPlaces[this.selectedPlaceIndex];
    if (!this.map || place.latitude === undefined || place.longitude === undefined) {
      return;
    }
    const camera: CameraPosition | undefined = this.map.getCameraPosition();
    this.map.animateCamera(CameraUpdateFactory.newCameraPosition(new CameraPosition(
      new LatLng(place.latitude, place.longitude),
      Math.max(17.9, camera?.zoom ?? 17.9), camera?.tilt ?? 45, camera?.bearing ?? 0)));
  }

  private drawOutsideMask(): void {
    if (!this.maskReady || this.maskWidth <= 0 || this.maskHeight <= 0) {
      return;
    }

    const context: CanvasRenderingContext2D = this.maskContext;
    context.clearRect(0, 0, this.maskWidth, this.maskHeight);
    context.fillStyle = '#FFFFFF';
    context.fillRect(0, 0, this.maskWidth, this.maskHeight);

    const projection = this.map?.getProjection();
    if (!projection) {
      return;
    }

    // 地图多边形贴在地面上，遮不住校外的 3D 建筑；屏幕遮罩能把校外整体留白。
    context.globalCompositeOperation = 'destination-out';
    context.beginPath();
    for (let index = 0; index < CAMPUS_BOUNDARY.length; index++) {
      const vertex: CampusCoordinate = CAMPUS_BOUNDARY[index];
      const point = projection.toScreenLocationSync(new LatLng(vertex.latitude, vertex.longitude));
      const x: number = this.getUIContext().px2vp(point.x);
      const y: number = this.getUIContext().px2vp(point.y);
      if (index === 0) {
        context.moveTo(x, y);
      } else {
        context.lineTo(x, y);
      }
    }
    context.closePath();
    context.fill();
    context.globalCompositeOperation = 'source-over';
  }

  build() {
    Stack() {
      MapViewComponent({ mapViewName: this.mapViewName })
        .width('100%')
        .height('100%')

      Canvas(this.maskContext)
        .width('100%')
        .height('100%')
        .hitTestBehavior(HitTestMode.None)
        .onReady((): void => {
          this.maskReady = true;
          this.drawOutsideMask();
        })
        .onAreaChange((_old: Area, area: Area): void => {
          this.maskWidth = Number(area.width);
          this.maskHeight = Number(area.height);
          this.drawOutsideMask();
        })

      Text('高德地图 · 边界 © OpenStreetMap contributors')
        .fontSize(10)
        .fontColor('#63717A')
        .backgroundColor('#F0FFFFFF')
        .padding(3)
        .position({ x: 8, y: 8 })
        .hitTestBehavior(HitTestMode.None)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }
}
