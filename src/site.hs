--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Hakyll
import qualified Data.Set as S
import           Text.Pandoc.Options
import           Control.Monad
--------------------------------------------------------------------------------

pandocMathCompiler =
    let mathExtensions = [Ext_tex_math_dollars, Ext_latex_macros,
                         Ext_backtick_code_blocks]
        defaultExtensions = writerExtensions defaultHakyllWriterOptions
        newExtensions = foldr S.insert defaultExtensions mathExtensions
        writerOptions = defaultHakyllWriterOptions {
                          writerExtensions = newExtensions,
                          writerHTMLMathMethod = MathJax ""
                        }
    in pandocCompilerWith defaultHakyllReaderOptions writerOptions


-- Plan
--
-- 1. Homepage with hard-coded set of items
-- 2. Specific pages, with the details of the things in each item.
-- 3. Don't do anything with vue
-- 4. Read the JSON file at compile time


main :: IO ()
main = hakyll $ do

    let items = ["retro-haskell", "the-cppn", "ai-fashion-designer"]

    match "images/**/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "files/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "js/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    -- TODO: Review.
    match "designs/*" $ do
        route $ setExtension "html"
        compile $ 
                (pandocMathCompiler)
            >>= saveSnapshot "content"
            >>= relativizeUrls

    match "index.html" $ do
        route idRoute
        compile $ do
            posts   <- (liftM (take 10)) $ recentFirst =<< loadAll "posts/*"
            designs <- recentFirst =<< loadAll "designs/*"

            -- error $ show designs

            let indexCtx =
                    listField "posts"   postCtx (return posts)   `mappend`
                    listField "designs" postCtx (return designs) `mappend`
                    constField "title" "Home"                    `mappend`
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateCompiler

    create ["atom.xml"] $ do
        route idRoute
        compile $ do
            let feedCtx = postCtx `mappend` bodyField "description"
            posts <- fmap (take 10) . recentFirst =<<
                loadAllSnapshots "posts/*" "content"
            renderAtom feedConf feedCtx posts


feedConf :: FeedConfiguration
feedConf = FeedConfiguration
    { feedTitle         = "vandersilk.github.io"
    , feedDescription   = "Website of Van der Silk"
    , feedAuthorName    = "Noon van der Silk"
    , feedAuthorEmail   = "noonsilk+-noonsilk@gmail.com"
    , feedRoot          = "https://vandersilk.github.io"
    }


--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext
