{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}

-----------------------------------------------------------------------------
-- |
-- Copyright   : (C) 2015 Dimitri Sabadie
-- License     : BSD3
--
-- Maintainer  : Dimitri Sabadie <dimitri.sabadie@gmail.com>
-- Stability   : experimental
-- Portability : portable
-----------------------------------------------------------------------------

module Graphics.Luminance.Core.Cubemap where

import Data.Proxy ( Proxy(..) )
import Data.Vector.Storable ( unsafeWith )
import Foreign.Ptr ( castPtr )
import Graphics.Luminance.Core.Texture ( BaseTexture(..), Texture(..) )
import Graphics.Luminance.Core.Pixel ( Pixel(..) )
import Graphics.GL
import Numeric.Natural ( Natural )

-- |Face of a 'Cubemap'.
data CubeFace
  = PositiveX
  | NegativeX
  | PositiveY
  | NegativeY
  | PositiveZ
  | NegativeZ
    deriving (Eq,Show)

fromCubeFace :: CubeFace -> GLint
fromCubeFace f = case f of
  PositiveX -> GL_TEXTURE_CUBE_MAP_POSITIVE_X
  NegativeX -> GL_TEXTURE_CUBE_MAP_NEGATIVE_X
  PositiveY -> GL_TEXTURE_CUBE_MAP_POSITIVE_Y
  NegativeY -> GL_TEXTURE_CUBE_MAP_NEGATIVE_Y
  PositiveZ -> GL_TEXTURE_CUBE_MAP_POSITIVE_Z
  NegativeZ -> GL_TEXTURE_CUBE_MAP_NEGATIVE_Z

-- |A cubemap.
data Cubemap f = Cubemap {
    cubemapBase :: BaseTexture
  , cubemapW    :: Natural
  , cubemapH    :: Natural
  } deriving (Eq,Show)

instance (Pixel f) => Texture (Cubemap f) where
  type TextureSize (Cubemap f) = (Natural,Natural)
  type TextureOffset (Cubemap f) = (Natural,Natural,CubeFace)
  fromBaseTexture bt (w,h) = Cubemap bt w h
  toBaseTexture = cubemapBase
  textureTypeEnum _ = GL_TEXTURE_CUBE_MAP
  textureSize (Cubemap _ w h) = (w,h)
  textureStorage _ tid levels (w,h) =
    glTextureStorage2D tid levels (pixelIFormat (Proxy :: Proxy f)) (fromIntegral w)
      (fromIntegral h)
  transferTexelsSub _ tid (x,y,f) (w,h) texels =
      unsafeWith texels $ glTextureSubImage3D tid 0 (fromIntegral x) (fromIntegral y)
        (fromCubeFace f) (fromIntegral w) (fromIntegral h) 1 fmt
        typ . castPtr
    where
      proxy = Proxy :: Proxy f
      fmt = pixelFormat proxy
      typ = pixelType proxy
  fillTextureSub _ tid (x,y,f) (w,h) filling =
      unsafeWith filling $ glClearTexSubImage tid 0 (fromIntegral x) (fromIntegral y) 
        (fromCubeFace f) (fromIntegral w) (fromIntegral h) 1
        fmt typ . castPtr
    where
      proxy = Proxy :: Proxy f
      fmt = pixelFormat proxy
      typ = pixelType proxy
