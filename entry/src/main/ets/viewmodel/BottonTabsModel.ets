import {BottonTabsItems} from "./BottonTabsItems"
export const BottonTabslist : Array<BottonTabsItems>=[
  {
    icon : $r("app.media.ic_home"),
    iconSelected : $r("app.media.ic_home_selected"),
    text : $r("app.string.bottom_text_map")
  },
  {
    icon : $r("app.media.ic_find"),
    iconSelected : $r("app.media.ic_find_selected"),
    text : $r("app.string.bottom_text_zones")
  },
  {
    icon : $r("app.media.ic_drive"),
    iconSelected : $r("app.media.ic_drive_selected"),
    text : $r("app.string.bottom_text_trains")
  },
  {
    icon : $r("app.media.ic_user"),
    iconSelected : $r("app.media.ic_user_selected"),
    text : $r("app.string.bottom_text_users")
  }
]
