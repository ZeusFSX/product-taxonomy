<p align="center"><img src="./dist/img/header.png" /></p>

<p align="center"><em><b>This is the development branch</b>. See <a href="https://github.com/Shopify/product-taxonomy/tree/releases"><code>releases</code></a> for stable distribution files.</em></p>

<!-- omit in toc -->
<h1 align="center">Shopify's Standard Product Taxonomy <a href="./VERSION"><img src="https://img.shields.io/badge/version-vUNRELEASED-orange.svg" alt="Version"></a></h1>

**🌍 Global Standard**: Our open-source, standardized product taxonomy establishes a universal language for product classification. Comprehensive and already empowering merchants on Shopify.

**👩🏼‍💻 Integration Friendly**: With a stable structure and diverse formats our taxonomy is designed for effortless integration into any system.

**🚀 Industry Benchmark**: Spanning 22 essential verticals, our taxonomy encompasses categories, attributes, and values, all thoughtfully integrated within Shopify and numerous marketplaces.

<p align="right"><em>Learn more on <a href="https://help.shopify.com/manual/products/details/product-category">help.shopify.com</a></em></p>

<!-- omit in toc -->
## 🗂️ Table of Contents

- [🕹️ Interactive explorer](#️-interactive-explorer)
- [📚 Taxonomy overview](#-taxonomy-overview)
- [🧭 Getting started](#-getting-started)
  - [🧩 How to integrate with the taxonomy](#-how-to-integrate-with-the-taxonomy)
    - [🗺️ Mapping to other taxonomies](#-mapping-to-other-taxonomies)
  - [🧑🏼‍🏫 How to make changes to the taxonomy](#-how-to-make-changes-to-the-taxonomy)
  - [👩🏼‍💻 How to evolve the system](#-how-to-evolve-the-system)
- [🤿 Diving in](#-diving-in)
- [🛠️ Setup and dependencies](#️-setup-and-dependencies)
- [📂 How this is all organized](#-how-this-is-all-organized)
- [📅 Releases](#-releases)
- [📜 License](#-license)

## 🕹️ Interactive explorer

Ready to dive in? [Explore our taxonomy interactively](https://shopify.github.io/product-taxonomy/releases/unstable/?categoryId=gid%3A%2F%2Fshopify%2FTaxonomy%2FCategory%2Fsg-4-17-2-17) to visualize and discover what's published across the many categories, attributes, and values.

## 📚 Taxonomy overview

Our taxonomy is an open-source comprehensive, global standard for product classification. It's a universal language that empowers merchants to categorize their products. Spanning 22 essential verticals, our taxonomy encompasses categories, attributes, and values, all thoughtfully integrated within Shopify and numerous marketplaces.

What's next? ⏭️ More attributes and values as we work to make this truly comprehensive.

## 🧭 Getting started

This repository is the home of Shopify's Standard Product Taxonomy. It houses the source-of-truth data, the distribution files for implementation, and the source code that makes this all sing.

We've structured it to be as user-friendly as possible, whether you're looking to integrate the taxonomy into your system, suggest changes, or delve into how it's developed and maintained.

### 🧩 How to integrate with the taxonomy

Dive straight into [`releases` branch](https://github.com/Shopify/product-taxonomy/tree/releases) to find the files you need and integrate this taxonomy into your system.

We're working on a variety of formats to make it easy to integrate with your systems. Today we have `txt` and `json` formats, and we're working on more. If you have a specific format you'd like to see, please open an issue and let us know!

#### 🗺️ Mapping to other taxonomies

To make it easier to integrate with the taxonomy, we have also included a set of data called _mappings_. These are rules that can be used to convert between categories and attributes in the Shopify taxonomy to categories and attributes of another taxonomy. For more on mappings see documentaton in the [integrations](./data/integrations/README.md) directory.

### 🧑🏼‍🏫 How to make changes to the taxonomy

> **🔵 Note**: While we are in preview we are not actively seeking PRs.

Everything comes from the source-of-truth files in [`data/`](./data). This is where you should submit PRs to change the taxonomy itself.

### 👩🏼‍💻 How to evolve the system

This system is how we manage the taxonomy and generate distributions. This is where the magic happens.

## 🤿 Diving in

This is a simple ruby app with a few models and serializers. The bulk of the work is parsing `data/` into a tree of `app/models/category.rb` to serialize reliably to `/dist/`. The app is setup to be rails-like, but is not a rails app, though is using `ActiveRecord`.

Everything ultimately runs through `make` (`dev` simply proxies). Here are the commands you'll use most often:

```sh
make [build] # build the dist and documentation files
make clean   # remove sentinels and all generated files
make seed    # parse /data into local db
make test    # run ruby tests and cue schema verification
make server  # http://localhost:4000 interactive view of /dist/
```

## 🛠️ Setup and dependencies

For Shopify employees or folks with [`minidev`](https://github.com/burke/minidev):
- Run `dev up`

For everyone else you'll need to:
- Install `ruby`, version matching `.ruby-version`
- Install [`cue`](https://github.com/cue-lang/cue?tab=readme-ov-file#download-and-install), version 0.7.x or higher
- Install `make`
- Run `bundle install`

When you edit any cue files, ensure you're running `cue fmt`. This will format the cue files to the standard format.

## 📂 How this is all organized

Most folks won't touch most of this, but we see you 👩🏼‍💻.

If you want to add a new serialization target, three simple steps:
1. Add a new serializer to `app/serializers`
2. Add the file load to `application.rb`
3. Extend `bin/generate_dist` to use your new serializer and write files

For your own explorations, here's a map of the land:

```
./
├── application.rb  # handles file loading "app-wide"
├── Makefile         # primary source of useful commands
├── Rakefile         # only used for testing
├── app/
│   ├── models/          # most models are simple data objects
│   │   ├── category.rb      # node-based tree impl for categories
│   │   └── ...
│   ├── serializers/
│   │   ├── data/        # object-centric, to read/write source-data files
│   │   ├── docs/        # object-centric, for docs site
│   │   └── dist/        # file-type-centric, for dist files
│   │       ├── json.rb
│   │       └── text.rb
│   └── services/        # classes for abstracting implementation details
├── bin/
│   ├── generate_dist    # file IO for /data → /dist
│   └── generate_docs    # file IO for /dist → /docs
├── db/
│   ├── schema.rb        # defines in-memory tables for models
│   └── seed.rb          # seed the db by parsing data shaped from /data
└── test/
```

## 📅 Releases

You can always find the current published version in [`VERSION`](./VERSION).  The changelog is available in [`CHANGELOG.md`](./CHANGELOG.md).

While this is `UNSTABLE`, we're using SemVer, but when this goes stable it will transition to [CalVer](https://calver.org/), in sync with [Shopify's API release schedule](https://shopify.dev/docs/api/usage/versioning#release-schedule).

That means a stable release every 3 months **at most**, at the beginning of the quarter. Version names are date-based to be meaningful and semantically unambiguous (for example, `2024-01`).

## 📜 License

Shopify's Product Taxonomy is released under the [MIT License](./LICENSE). So go ahead, explore, play, and build something awesome!
