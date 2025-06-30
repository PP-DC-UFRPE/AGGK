{-# LANGUAGE CPP #-}
{-# LANGUAGE NoRebindableSyntax #-}
{-# OPTIONS_GHC -fno-warn-missing-import-lists #-}
module Paths_banco_investimentos_haskell (
    version,
    getBinDir, getLibDir, getDynLibDir, getDataDir, getLibexecDir,
    getDataFileName, getSysconfDir
  ) where

import qualified Control.Exception as Exception
import Data.Version (Version(..))
import System.Environment (getEnv)
import Prelude

#if defined(VERSION_base)

#if MIN_VERSION_base(4,0,0)
catchIO :: IO a -> (Exception.IOException -> IO a) -> IO a
#else
catchIO :: IO a -> (Exception.Exception -> IO a) -> IO a
#endif

#else
catchIO :: IO a -> (Exception.IOException -> IO a) -> IO a
#endif
catchIO = Exception.catch

version :: Version
version = Version [0,1,0,0] []
bindir, libdir, dynlibdir, datadir, libexecdir, sysconfdir :: FilePath

bindir     = "C:\\cabal\\bin"
libdir     = "C:\\cabal\\x86_64-windows-ghc-8.6.5\\banco-investimentos-haskell-0.1.0.0-C4nbDUtlDUy53j5H2wD5dz"
dynlibdir  = "C:\\cabal\\x86_64-windows-ghc-8.6.5"
datadir    = "C:\\cabal\\x86_64-windows-ghc-8.6.5\\banco-investimentos-haskell-0.1.0.0"
libexecdir = "C:\\cabal\\banco-investimentos-haskell-0.1.0.0-C4nbDUtlDUy53j5H2wD5dz\\x86_64-windows-ghc-8.6.5\\banco-investimentos-haskell-0.1.0.0"
sysconfdir = "C:\\cabal\\etc"

getBinDir, getLibDir, getDynLibDir, getDataDir, getLibexecDir, getSysconfDir :: IO FilePath
getBinDir = catchIO (getEnv "banco_investimentos_haskell_bindir") (\_ -> return bindir)
getLibDir = catchIO (getEnv "banco_investimentos_haskell_libdir") (\_ -> return libdir)
getDynLibDir = catchIO (getEnv "banco_investimentos_haskell_dynlibdir") (\_ -> return dynlibdir)
getDataDir = catchIO (getEnv "banco_investimentos_haskell_datadir") (\_ -> return datadir)
getLibexecDir = catchIO (getEnv "banco_investimentos_haskell_libexecdir") (\_ -> return libexecdir)
getSysconfDir = catchIO (getEnv "banco_investimentos_haskell_sysconfdir") (\_ -> return sysconfdir)

getDataFileName :: FilePath -> IO FilePath
getDataFileName name = do
  dir <- getDataDir
  return (dir ++ "\\" ++ name)
