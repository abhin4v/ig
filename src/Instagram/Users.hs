{-# LANGUAGE FlexibleContexts #-}
-- | Users end point handling
module Instagram.Users (
  RecentParams(..)
  ,getRecent
  ,SelfLikedParams(..)
  ,getSelfLiked
) where

import Instagram.Monad
import Instagram.Types

import Data.Time.Clock.POSIX (POSIXTime)
import Data.Typeable (Typeable)

import qualified Network.HTTP.Types as HT
import Data.ByteString.Char8 (pack)
import Data.Maybe (isJust)
import qualified Data.Text as T (Text,concat)
import Data.Conduit
import qualified Data.Text.Encoding as TE

import Data.Default

type UserID = T.Text

data RecentParams = RecentParams {
    rpCount :: Maybe Int,
    rpMaxTimestamp :: Maybe POSIXTime,
    rpMinTimestamp :: Maybe POSIXTime,
    rpMaxID :: Maybe String,
    rpMinId :: Maybe String
  }
  deriving (Show,Typeable)
  
instance Default RecentParams where
  def=RecentParams Nothing Nothing Nothing Nothing Nothing
  
instance HT.QueryLike RecentParams where
  toQuery (RecentParams c maxT minT maxI minI)=filter (isJust .snd) 
    [("count",fmap (pack . show) c)
    ,("max_timestamp",fmap (pack . show . round) maxT)
    ,("min_timestamp",fmap (pack . show . round) minT)
    ,("max_id",fmap (pack . show) maxI)
    ,("min_id",fmap (pack . show) minI)]
    
    
getRecent :: (MonadBaseControl IO m, MonadResource m) => UserID 
  -> AccessToken
  -> RecentParams 
  -> InstagramT m (Envelope [Media])
getRecent uid token rp=do
  let url=TE.encodeUtf8 $ T.concat ["/v1/users/",uid,"/media/recent/"]
  getSimpleQueryGetRequest url (addToken token rp)>>= getJSONEnvelope

data SelfLikedParams = SelfLikedParams {
  slpCount :: Maybe Int,
  slpMaxLikeID :: Maybe String
  }
  deriving (Show,Typeable)
  
instance Default SelfLikedParams where
  def=SelfLikedParams Nothing Nothing
  
instance HT.QueryLike SelfLikedParams where
  toQuery (SelfLikedParams c maxI)=filter (isJust .snd) 
    [("count",fmap (pack . show) c)
    ,("max_like_id",fmap (pack . show) maxI)] 

getSelfLiked :: (MonadBaseControl IO m, MonadResource m) => OAuthToken 
  -> SelfLikedParams
  -> InstagramT m (Envelope [Media]) 
getSelfLiked token slp=do
  let url="/v1/users/self/media/liked"
  getSimpleQueryGetRequest url (addToken (oaAccessToken token) slp)>>= getJSONEnvelope
