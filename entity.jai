
ModelPlacement :: enum {
    BOTTOM;
    CENTER;
}

Entity :: struct {
    using position : Vector3;
    orientation : Quaternion;
    placement := ModelPlacement.BOTTOM;
}

