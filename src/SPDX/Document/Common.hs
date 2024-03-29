{-# LANGUAGE DeriveGeneric             #-}
{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE GADTs                     #-}
{-# LANGUAGE LambdaCase                #-}
{-# LANGUAGE OverloadedStrings         #-}
{-# LANGUAGE TypeFamilies              #-}

module SPDX.Document.Common where

import           MyPrelude

import qualified Data.Aeson          as A
import qualified Data.Aeson.Types    as A
import qualified Data.List           as List
import qualified Data.Text           as T
import qualified Distribution.Parsec as SPDX
import qualified Distribution.SPDX   as SPDX

type SPDXID = String

class SPDXIDable a where
  getSPDXID :: a -> SPDXID
  matchesSPDXID :: a -> SPDXID -> Bool
  matchesSPDXID a = ((getSPDXID a) ==)

data SPDXMaybe a
  = SPDXJust a
  | NOASSERTION
  | NONE
  deriving (Eq)

instance (Show a) => Show (SPDXMaybe a) where
  show (SPDXJust a) = show a
  show NOASSERTION  = "NOASSERTION"
  show NONE         = "NONE"

instance (A.FromJSON a) => A.FromJSON (SPDXMaybe a) where
  parseJSON =
    A.withText "SPDXMaybe" $ \case
      "NOASSERTION" -> pure NOASSERTION
      "NONE"        -> pure NONE
      text          -> fmap SPDXJust (A.parseJSON (A.String text))

spdxMaybeToMaybe :: SPDXMaybe a -> Maybe a
spdxMaybeToMaybe (SPDXJust a) = Just a
spdxMaybeToMaybe _            = Nothing

instance Foldable SPDXMaybe where
  foldMap f (SPDXJust x) = f x
  foldMap f _            = mempty
  foldr f z (SPDXJust x) = f x z
  foldr _ z _            = z
  foldl f z (SPDXJust x) = f z x
  foldl _ z _            = z

data SPDXChecksumAlgorithm
  = SHA256
  | SHA1
  | SHA384
  | MD2
  | MD4
  | SHA512
  | MD6
  | MD5
  | SHA224
  | SHA3256
  | SHA3384
  | SHA3512
  | BLAKE2b256
  | BLAKE2b384
  | BLAKE2b512
  | BLAKE3
  | ADLER32
  deriving (Eq, Show, Generic)

instance A.FromJSON SPDXChecksumAlgorithm where
  parseJSON  = A.withText "SPDXChecksumAlgorithm" $ \t -> case T.unpack t of
    "SHA256" ->        return SHA256                  
    "SHA1" ->          return SHA1                  
    "SHA384" ->        return SHA384                  
    "MD2" ->           return MD2                  
    "MD4" ->           return MD4                  
    "SHA512" ->        return SHA512                  
    "MD6" ->           return MD6                  
    "MD5" ->           return MD5                  
    "SHA224" ->        return SHA224                  
    "SHA3-256" ->      return  SHA3256                  
    "SHA3-384" ->      return  SHA3384                  
    "SHA3-512" ->      return  SHA3512                  
    "BLAKE2b-256" ->   return  BLAKE2b256                  
    "BLAKE2b-384" ->   return  BLAKE2b384                  
    "BLAKE2b-512" ->   return  BLAKE2b512                  
    "BLAKE3" ->        return BLAKE3               
    "ADLER32" ->       return ADLER32               
    t -> fail ("not supported SPDXChecksumAlgorithm: " ++ t)  


data SPDXChecksum =
  SPDXChecksum
    { _SPDXChecksum_algorithm     :: SPDXChecksumAlgorithm
    , _SPDXChecksum_checksumValue :: String
    }
  deriving (Eq, Show)

--               "checksums" : {
--                 "description" : "The checksum property provides a mechanism that can be used to verify that the contents of a File or Package have not changed.",
--                 "type" : "array",
--                 "items" : {
--                   "type" : "object",
--                   "properties" : {
--                     "algorithm" : {
--                       "description" : "Identifies the algorithm used to produce the subject Checksum. Currently, SHA-1 is the only supported algorithm. It is anticipated that other algorithms will be supported at a later time.",
--                       "type" : "string",
--                       "enum" : [ "SHA256", "SHA1", "SHA384", "MD2", "MD4", "SHA512", "MD6", "MD5", "SHA224" ]
--                     },
--                     "checksumValue" : {
--                       "description" : "The checksumValue property provides a lower case hexidecimal encoded digest value produced using a specific algorithm.",
--                       "type" : "string"
--                     }
--                   },
--                   "description" : "A Checksum is value that allows the contents of a file to be authenticated. Even small changes to the content of the file will change its checksum. This class allows the results of a variety of checksum and cryptographic message digest algorithms to be represented."
--                 },
--                 "minItems" : 1
--               },
instance A.FromJSON SPDXChecksum where
  parseJSON =
    A.withObject "SPDXChecksum" $ \v ->
      SPDXChecksum <$> v A..: "algorithm" <*> v A..: "checksumValue"
