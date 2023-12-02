import pandas as pd
from pyometiff import OMETIFFReader

if __name__ == '__main__':


    reader = OMETIFFReader(fpath=fn)
    img_array,metadata,xml_metadata=reader.read()
    ## Extract pixel width and height
    pixel_width=np.float64(metadata['PhysicalSizeX'])
    pixel_height=np.float64(metadata['PhysicalSizeY'])
    
    ## Calculate pixel coordinates for nucleus/cell boundaries
    nucleus_bound['vertex_x_pixel']=(nucleus_bound['vertex_x']/pixel_width).apply(lambda x: round(x))
    nucleus_bound['vertex_y_pixel']=(nucleus_bound['vertex_y']/pixel_height).apply(lambda x: round(x))