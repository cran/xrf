library(testthat)

context('model sanity checks')

data('mtcars')
dataset <- mtcars %>%
  rbind(mtcars) %>% # double the dataset to avoid small class priors for glmnet cross validation
  mutate(
    vs = as.factor(vs),
    am = as.factor(am)
  )

test_expected_fields <- function(model, depth, trees) {
  max_splits <- (2 ^ (depth + 1) - 2) * trees # number of edges in a binary tree for each tree = number of nodes - 1
  max_rules <- 2 ^ depth * trees # number of root -> leaf traversals in a binary tree for each tree

  expected_max_coef <- 1 + # intercept
    1 + # continuous mpg
    1 + # continuous displacement
    length(unique(dataset$cyl)) - 1 +
    max_rules

  expect_setequal(c('glm', 'xgb', 'base_formula', 'rule_augmented_formula', 'rules'), names(model))
  expect_s3_class(model$glm, 'glmnot')
  expect_s3_class(model$xgb, 'xgb.Booster')
  expect_s3_class(model$base_formula, 'formula')
  expect_s3_class(model$rule_augmented_formula, 'formula')
  expect_s3_class(model$rules, 'data.frame')

  expect_lte(nrow(model$rules), max_splits)
  expect_lte(n_distinct(model$rules$rule_id), max_rules)
  expect_lte(nrow(coef(model, lambda = 'lambda.min')), expected_max_coef)
}

test_that('model from dense design matrix has expected fields', {
  depth <- 2
  trees <- 3
  m_xrf <- xrf(am ~ mpg + as.factor(cyl) + disp, dataset, family = 'binomial',
               xgb_control = list(nrounds = trees, max_depth = depth), sparse = FALSE)

  test_expected_fields(m_xrf, depth, trees)
})

test_that('model from sparse design matrix has expected fields', {
  depth <- 2
  trees <- 3
  m_xrf <- xrf(am ~ mpg + cyl + disp, dataset, family = 'binomial',
               xgb_control = list(nrounds = 3, max_depth = 2))

  test_expected_fields(m_xrf, depth, trees)
})

test_that('model predicts binary outcome', {
  m_xrf <- xrf(am ~ mpg + cyl + disp + hp + drat + wt + qsec, dataset, family = 'binomial',
               xgb_control = list(nrounds = 3, max_depth = 2),
               glm_control = list(type.measure='deviance', nfolds=10))
  preds_response_dense <- predict(m_xrf, dataset, type = 'response', sparse = FALSE)
  preds_response_sparse <- predict(m_xrf, dataset, type = 'response', sparse = TRUE)

  preds_link <- predict(m_xrf, dataset, type = 'link')

  expect_equal(preds_response_dense, preds_response_sparse)
  expect(all(preds_response_dense < 1 & preds_response_dense > 0), 'Binomial predicted outcome does not represent a valid posterior')
  expect(all(preds_response_sparse< 1 & preds_response_sparse > 0), 'Binomial predicted outcome does not represent a valid posterior')
  # since we are using deviance on the LASSO fit, the model should be calibrated
  expect_equal(mean(preds_response_dense), mean(dataset$am == '1'))

  expect(any(preds_link < 0 | preds_link > 1), 'Link predictions appear to be probabilities')
})

test_that('model predicts continuous outcome', {
  m_xrf <- xrf(mpg ~ ., dataset, family = 'gaussian',
               xgb_control = list(nrounds = 3, max_depth = 2),
               glm_control = list(type.measure='deviance', nfolds=10))

  preds <- predict(m_xrf, dataset, type = 'response', sparse = FALSE)

  expect_equal(mean(preds), mean(dataset$mpg))
  mae <- mean(abs(preds - dataset$mpg))
  expect_lt(mae, 5) # since this should be highly parameterized / overfit
})


test_that('model predicts without outcome column', {
 # issue #9
  mod <- xrf(mpg ~ ., data = mtcars[-(1:5), ],
             xgb_control = list(nrounds = 5, max_depth = 2),
             family = "gaussian")
  expect_equal(predict(mod, mtcars[1:5, ])[,1], predict(mod, mtcars[1:5, -1])[,1])

  mod_nsp <- xrf(mpg ~ ., data = mtcars[-(1:5), ],
                 xgb_control = list(nrounds = 5, max_depth = 2),
                 family = "gaussian", sparse = FALSE)
  expect_equal(predict(mod_nsp, mtcars[1:5, ],   sparse = FALSE)[, 1],
               predict(mod_nsp, mtcars[1:5, -1], sparse = FALSE)[, 1])
})

test_that('call scrubbed', {
  mod_nsp <- xrf(mpg ~ ., data = mtcars[-(1:5), ],
                 xgb_control = list(nrounds = 5, max_depth = 2),
                 family = "gaussian", sparse = FALSE)

  # in previous version:
  # > object.size(mod_nsp$glm$model$call)
  # 211544 bytes
  expect_true(object.size(mod_nsp$glm$model$call) < 211544)
})


test_that('single feature model', {
  set.seed(55414)
  x1 <- rbinom(100, 1, .7)
  y <- rnorm(100, 0, .5) + x1
  dat <- data.frame(y, x1)
  mod <- xrf(y ~ x1, data = dat,
                 xgb_control = list(nrounds = 5, max_depth = 2),
                 family = "gaussian", sparse = FALSE)
  expect_gt(nrow(mod$rules), 0)
})

