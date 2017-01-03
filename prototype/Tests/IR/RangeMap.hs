{-# LANGUAGE UndecidableInstances #-}
module Tests.IR.RangeMap where

import Control.Applicative ((<$>), (<*>))
import Control.Monad.Identity (Identity(..))
import Test.Framework (testGroup)
import Test.Framework.Providers.QuickCheck2 (testProperty)
import Test.QuickCheck.Arbitrary (Arbitrary, arbitrary)
import Test.QuickCheck.Instances
import Layout.IR.RangeMap
    ( FieldMap(..)
    , Indexed(..)
    , RangeMap(..)
    , chunkBytes
    )

instance Arbitrary a => Arbitrary (Indexed a) where
    arbitrary = Indexed <$> arbitrary <*> arbitrary

instance Arbitrary RangeMap where
    arbitrary = RangeMap <$> arbitrary <*> arbitrary <*> arbitrary

instance Arbitrary (f RangeMap) => Arbitrary (FieldMap f) where
    arbitrary = FieldMap <$> arbitrary

instance Functor Indexed where
    fmap f (Indexed n x) = Indexed n (f x)

totalSize :: (bucket RangeMap -> RangeMap) -> FieldMap bucket -> Int
totalSize stripBucket = sum . map rangeLen . allRangeMaps stripBucket

allRangeMaps stripBucket (FieldMap fm) = concat $ map (map stripBucket . snd) fm

stripIndexed (Indexed _ x) = x

rangeMapTests = testGroup "Range map tests"
    [ testProperty "chunkBytes preserves total size."
        (\fm -> totalSize runIdentity fm == totalSize stripIndexed (chunkBytes fm))
    , testProperty "chunkBytes doesn't make ranges > 8 bits"
        (\fm -> and $ map ((<= 8) . rangeLen) $ allRangeMaps stripIndexed (chunkBytes fm))
    ]
