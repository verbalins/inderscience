# Article format for Inderscience publications

This is a Quarto template that assists you in creating a manuscript for Inderscience journals.

## Creating a New Article

You can use this as a template to create an article for an Inderscience journal. To do this, use the following command:

```bash
quarto use template verbalins/inderscience
```

This will install the extension and create an example qmd file and bibiography that you can use as a starting place for your article.

## Installation For Existing Document

You may also use this format with an existing Quarto project or document. From the quarto project or document directory, run the following command to install this format:

```bash
quarto install extension verbalins/inderscience
```

## Usage

To use the format, you can use the format names `inderscience-pdf` and `inderscience-html`. For example:

```bash
quarto render template.qmd --to inderscience-pdf
```

or in your document yaml

```yaml
format:
  inderscience-pdf:
    keep-tex: true    
```

## Format Options

This format does not have specific format option. Include documentation of such option otherwise. See <https://github.com/quarto-journals/elsevier#format-options> for an example.
